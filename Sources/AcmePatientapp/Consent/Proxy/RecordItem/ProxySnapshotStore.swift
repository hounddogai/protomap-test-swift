import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy snapshots by code.
    protocol ProxySnapshotStore {
        func find(_ code: String) -> ProxySnapshot?
        func save(_ item: ProxySnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [ProxySnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxySnapshotStore: ProxySnapshotStore {
        var items: [String: ProxySnapshot]
        var order: [String]

        init(items: [String: ProxySnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxySnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxySnapshot) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [ProxySnapshot] {
            var out: [ProxySnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxySnapshotStore() -> any ProxySnapshotStore {
        return MemoryProxySnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxySnapshotStore: ProxySnapshotStore {
        var inner: MemoryProxySnapshotStore
        var cache: TTLCache<ProxySnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxySnapshotStore, cache: TTLCache<ProxySnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxySnapshot? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: ProxySnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxySnapshot] {
            return inner.list()
        }
    }

    static func newCachedProxySnapshotStore(_ inner: MemoryProxySnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxySnapshotStore {
        return CachedProxySnapshotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy snapshots. Empty fields match all.
    final class ProxySnapshotQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxySnapshot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxySnapshot]) -> [ProxySnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxySnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxySnapshots(_ store: any ProxySnapshotStore, query: ProxySnapshotQuery) -> [ProxySnapshot] {
        return query.apply(store.list())
    }
}

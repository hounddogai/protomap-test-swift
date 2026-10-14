import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive panel snapshots by code.
    protocol AdaptivePanelSnapshotStore {
        func find(_ code: String) -> AdaptivePanelSnapshot?
        func save(_ item: AdaptivePanelSnapshot)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePanelSnapshot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePanelSnapshotStore: AdaptivePanelSnapshotStore {
        var items: [String: AdaptivePanelSnapshot]
        var order: [String]

        init(items: [String: AdaptivePanelSnapshot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePanelSnapshot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePanelSnapshot) {
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

        func list() -> [AdaptivePanelSnapshot] {
            var out: [AdaptivePanelSnapshot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePanelSnapshotStore() -> any AdaptivePanelSnapshotStore {
        return MemoryAdaptivePanelSnapshotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePanelSnapshotStore: AdaptivePanelSnapshotStore {
        var inner: MemoryAdaptivePanelSnapshotStore
        var cache: TTLCache<AdaptivePanelSnapshot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePanelSnapshotStore, cache: TTLCache<AdaptivePanelSnapshot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePanelSnapshot? {
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

        func save(_ item: AdaptivePanelSnapshot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePanelSnapshot] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePanelSnapshotStore(_ inner: MemoryAdaptivePanelSnapshotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePanelSnapshotStore {
        return CachedAdaptivePanelSnapshotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive panel snapshots. Empty fields match all.
    final class AdaptivePanelSnapshotQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePanelSnapshot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePanelSnapshot]) -> [AdaptivePanelSnapshot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePanelSnapshot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePanelSnapshots(_ store: any AdaptivePanelSnapshotStore, query: AdaptivePanelSnapshotQuery) -> [AdaptivePanelSnapshot] {
        return query.apply(store.list())
    }
}

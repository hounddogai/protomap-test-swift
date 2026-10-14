import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy checkpoints by code.
    protocol ProxyCheckpointStore {
        func find(_ code: String) -> ProxyCheckpoint?
        func save(_ item: ProxyCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyCheckpointStore: ProxyCheckpointStore {
        var items: [String: ProxyCheckpoint]
        var order: [String]

        init(items: [String: ProxyCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyCheckpoint) {
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

        func list() -> [ProxyCheckpoint] {
            var out: [ProxyCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyCheckpointStore() -> any ProxyCheckpointStore {
        return MemoryProxyCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyCheckpointStore: ProxyCheckpointStore {
        var inner: MemoryProxyCheckpointStore
        var cache: TTLCache<ProxyCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyCheckpointStore, cache: TTLCache<ProxyCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyCheckpoint? {
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

        func save(_ item: ProxyCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedProxyCheckpointStore(_ inner: MemoryProxyCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyCheckpointStore {
        return CachedProxyCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy checkpoints. Empty fields match all.
    final class ProxyCheckpointQuery {
        var locale: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCost: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyCheckpoint]) -> [ProxyCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyCheckpoints(_ store: any ProxyCheckpointStore, query: ProxyCheckpointQuery) -> [ProxyCheckpoint] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global revocation rollups by code.
    protocol GlobalRevocationRollupStore {
        func find(_ code: String) -> GlobalRevocationRollup?
        func save(_ item: GlobalRevocationRollup)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRevocationRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRevocationRollupStore: GlobalRevocationRollupStore {
        var items: [String: GlobalRevocationRollup]
        var order: [String]

        init(items: [String: GlobalRevocationRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRevocationRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRevocationRollup) {
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

        func list() -> [GlobalRevocationRollup] {
            var out: [GlobalRevocationRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRevocationRollupStore() -> any GlobalRevocationRollupStore {
        return MemoryGlobalRevocationRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRevocationRollupStore: GlobalRevocationRollupStore {
        var inner: MemoryGlobalRevocationRollupStore
        var cache: TTLCache<GlobalRevocationRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRevocationRollupStore, cache: TTLCache<GlobalRevocationRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRevocationRollup? {
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

        func save(_ item: GlobalRevocationRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRevocationRollup] {
            return inner.list()
        }
    }

    static func newCachedGlobalRevocationRollupStore(_ inner: MemoryGlobalRevocationRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRevocationRollupStore {
        return CachedGlobalRevocationRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global revocation rollups. Empty fields match all.
    final class GlobalRevocationRollupQuery {
        var segment: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minPriority: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRevocationRollup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalRevocationRollup]) -> [GlobalRevocationRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRevocationRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRevocationRollups(_ store: any GlobalRevocationRollupStore, query: GlobalRevocationRollupQuery) -> [GlobalRevocationRollup] {
        return query.apply(store.list())
    }
}

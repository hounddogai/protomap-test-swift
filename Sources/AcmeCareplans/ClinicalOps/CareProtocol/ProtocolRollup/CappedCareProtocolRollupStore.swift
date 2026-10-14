import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped care protocol rollups by code.
    protocol CappedCareProtocolRollupStore {
        func find(_ code: String) -> CappedCareProtocolRollup?
        func save(_ item: CappedCareProtocolRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCareProtocolRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCareProtocolRollupStore: CappedCareProtocolRollupStore {
        var items: [String: CappedCareProtocolRollup]
        var order: [String]

        init(items: [String: CappedCareProtocolRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCareProtocolRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCareProtocolRollup) {
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

        func list() -> [CappedCareProtocolRollup] {
            var out: [CappedCareProtocolRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCareProtocolRollupStore() -> any CappedCareProtocolRollupStore {
        return MemoryCappedCareProtocolRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCareProtocolRollupStore: CappedCareProtocolRollupStore {
        var inner: MemoryCappedCareProtocolRollupStore
        var cache: TTLCache<CappedCareProtocolRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCareProtocolRollupStore, cache: TTLCache<CappedCareProtocolRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCareProtocolRollup? {
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

        func save(_ item: CappedCareProtocolRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCareProtocolRollup] {
            return inner.list()
        }
    }

    static func newCachedCappedCareProtocolRollupStore(_ inner: MemoryCappedCareProtocolRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCareProtocolRollupStore {
        return CachedCappedCareProtocolRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped care protocol rollups. Empty fields match all.
    final class CappedCareProtocolRollupQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCareProtocolRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedCareProtocolRollup]) -> [CappedCareProtocolRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCareProtocolRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCareProtocolRollups(_ store: any CappedCareProtocolRollupStore, query: CappedCareProtocolRollupQuery) -> [CappedCareProtocolRollup] {
        return query.apply(store.list())
    }
}

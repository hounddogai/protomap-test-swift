import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol rollups by code.
    protocol CareProtocolRollupStore {
        func find(_ code: String) -> CareProtocolRollup?
        func save(_ item: CareProtocolRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolRollupStore: CareProtocolRollupStore {
        var items: [String: CareProtocolRollup]
        var order: [String]

        init(items: [String: CareProtocolRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolRollup) {
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

        func list() -> [CareProtocolRollup] {
            var out: [CareProtocolRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolRollupStore() -> any CareProtocolRollupStore {
        return MemoryCareProtocolRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolRollupStore: CareProtocolRollupStore {
        var inner: MemoryCareProtocolRollupStore
        var cache: TTLCache<CareProtocolRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolRollupStore, cache: TTLCache<CareProtocolRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolRollup? {
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

        func save(_ item: CareProtocolRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolRollup] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolRollupStore(_ inner: MemoryCareProtocolRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolRollupStore {
        return CachedCareProtocolRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol rollups. Empty fields match all.
    final class CareProtocolRollupQuery {
        var ward: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRefills: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolRollup) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolRollup]) -> [CareProtocolRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolRollups(_ store: any CareProtocolRollupStore, query: CareProtocolRollupQuery) -> [CareProtocolRollup] {
        return query.apply(store.list())
    }
}

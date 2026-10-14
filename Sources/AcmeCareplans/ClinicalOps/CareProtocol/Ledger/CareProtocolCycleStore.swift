import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol cycles by code.
    protocol CareProtocolCycleStore {
        func find(_ code: String) -> CareProtocolCycle?
        func save(_ item: CareProtocolCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolCycleStore: CareProtocolCycleStore {
        var items: [String: CareProtocolCycle]
        var order: [String]

        init(items: [String: CareProtocolCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolCycle) {
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

        func list() -> [CareProtocolCycle] {
            var out: [CareProtocolCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolCycleStore() -> any CareProtocolCycleStore {
        return MemoryCareProtocolCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolCycleStore: CareProtocolCycleStore {
        var inner: MemoryCareProtocolCycleStore
        var cache: TTLCache<CareProtocolCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolCycleStore, cache: TTLCache<CareProtocolCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolCycle? {
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

        func save(_ item: CareProtocolCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolCycle] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolCycleStore(_ inner: MemoryCareProtocolCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolCycleStore {
        return CachedCareProtocolCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol cycles. Empty fields match all.
    final class CareProtocolCycleQuery {
        var facility: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minScore: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolCycle]) -> [CareProtocolCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolCycles(_ store: any CareProtocolCycleStore, query: CareProtocolCycleQuery) -> [CareProtocolCycle] {
        return query.apply(store.list())
    }
}

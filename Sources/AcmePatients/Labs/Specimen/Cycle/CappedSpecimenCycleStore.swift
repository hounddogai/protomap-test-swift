import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped specimen cycles by code.
    protocol CappedSpecimenCycleStore {
        func find(_ code: String) -> CappedSpecimenCycle?
        func save(_ item: CappedSpecimenCycle)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSpecimenCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSpecimenCycleStore: CappedSpecimenCycleStore {
        var items: [String: CappedSpecimenCycle]
        var order: [String]

        init(items: [String: CappedSpecimenCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSpecimenCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSpecimenCycle) {
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

        func list() -> [CappedSpecimenCycle] {
            var out: [CappedSpecimenCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSpecimenCycleStore() -> any CappedSpecimenCycleStore {
        return MemoryCappedSpecimenCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSpecimenCycleStore: CappedSpecimenCycleStore {
        var inner: MemoryCappedSpecimenCycleStore
        var cache: TTLCache<CappedSpecimenCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSpecimenCycleStore, cache: TTLCache<CappedSpecimenCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSpecimenCycle? {
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

        func save(_ item: CappedSpecimenCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSpecimenCycle] {
            return inner.list()
        }
    }

    static func newCachedCappedSpecimenCycleStore(_ inner: MemoryCappedSpecimenCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSpecimenCycleStore {
        return CachedCappedSpecimenCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped specimen cycles. Empty fields match all.
    final class CappedSpecimenCycleQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSpecimenCycle) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSpecimenCycle]) -> [CappedSpecimenCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSpecimenCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSpecimenCycles(_ store: any CappedSpecimenCycleStore, query: CappedSpecimenCycleQuery) -> [CappedSpecimenCycle] {
        return query.apply(store.list())
    }
}

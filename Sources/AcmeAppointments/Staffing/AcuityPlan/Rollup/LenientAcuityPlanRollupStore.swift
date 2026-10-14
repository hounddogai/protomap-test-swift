import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient acuity plan rollups by code.
    protocol LenientAcuityPlanRollupStore {
        func find(_ code: String) -> LenientAcuityPlanRollup?
        func save(_ item: LenientAcuityPlanRollup)
        func remove(_ code: String) -> Bool
        func list() -> [LenientAcuityPlanRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientAcuityPlanRollupStore: LenientAcuityPlanRollupStore {
        var items: [String: LenientAcuityPlanRollup]
        var order: [String]

        init(items: [String: LenientAcuityPlanRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientAcuityPlanRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientAcuityPlanRollup) {
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

        func list() -> [LenientAcuityPlanRollup] {
            var out: [LenientAcuityPlanRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientAcuityPlanRollupStore() -> any LenientAcuityPlanRollupStore {
        return MemoryLenientAcuityPlanRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientAcuityPlanRollupStore: LenientAcuityPlanRollupStore {
        var inner: MemoryLenientAcuityPlanRollupStore
        var cache: TTLCache<LenientAcuityPlanRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientAcuityPlanRollupStore, cache: TTLCache<LenientAcuityPlanRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientAcuityPlanRollup? {
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

        func save(_ item: LenientAcuityPlanRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientAcuityPlanRollup] {
            return inner.list()
        }
    }

    static func newCachedLenientAcuityPlanRollupStore(_ inner: MemoryLenientAcuityPlanRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientAcuityPlanRollupStore {
        return CachedLenientAcuityPlanRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient acuity plan rollups. Empty fields match all.
    final class LenientAcuityPlanRollupQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientAcuityPlanRollup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [LenientAcuityPlanRollup]) -> [LenientAcuityPlanRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientAcuityPlanRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientAcuityPlanRollups(_ store: any LenientAcuityPlanRollupStore, query: LenientAcuityPlanRollupQuery) -> [LenientAcuityPlanRollup] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps lenient acuity plan baselines by code.
    protocol LenientAcuityPlanBaselineStore {
        func find(_ code: String) -> LenientAcuityPlanBaseline?
        func save(_ item: LenientAcuityPlanBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LenientAcuityPlanBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientAcuityPlanBaselineStore: LenientAcuityPlanBaselineStore {
        var items: [String: LenientAcuityPlanBaseline]
        var order: [String]

        init(items: [String: LenientAcuityPlanBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientAcuityPlanBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientAcuityPlanBaseline) {
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

        func list() -> [LenientAcuityPlanBaseline] {
            var out: [LenientAcuityPlanBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientAcuityPlanBaselineStore() -> any LenientAcuityPlanBaselineStore {
        return MemoryLenientAcuityPlanBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientAcuityPlanBaselineStore: LenientAcuityPlanBaselineStore {
        var inner: MemoryLenientAcuityPlanBaselineStore
        var cache: TTLCache<LenientAcuityPlanBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientAcuityPlanBaselineStore, cache: TTLCache<LenientAcuityPlanBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientAcuityPlanBaseline? {
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

        func save(_ item: LenientAcuityPlanBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientAcuityPlanBaseline] {
            return inner.list()
        }
    }

    static func newCachedLenientAcuityPlanBaselineStore(_ inner: MemoryLenientAcuityPlanBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientAcuityPlanBaselineStore {
        return CachedLenientAcuityPlanBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient acuity plan baselines. Empty fields match all.
    final class LenientAcuityPlanBaselineQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientAcuityPlanBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientAcuityPlanBaseline]) -> [LenientAcuityPlanBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientAcuityPlanBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientAcuityPlanBaselines(_ store: any LenientAcuityPlanBaselineStore, query: LenientAcuityPlanBaselineQuery) -> [LenientAcuityPlanBaseline] {
        return query.apply(store.list())
    }
}

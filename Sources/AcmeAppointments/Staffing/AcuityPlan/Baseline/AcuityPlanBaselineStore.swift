import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan baselines by code.
    protocol AcuityPlanBaselineStore {
        func find(_ code: String) -> AcuityPlanBaseline?
        func save(_ item: AcuityPlanBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanBaselineStore: AcuityPlanBaselineStore {
        var items: [String: AcuityPlanBaseline]
        var order: [String]

        init(items: [String: AcuityPlanBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanBaseline) {
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

        func list() -> [AcuityPlanBaseline] {
            var out: [AcuityPlanBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanBaselineStore() -> any AcuityPlanBaselineStore {
        return MemoryAcuityPlanBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanBaselineStore: AcuityPlanBaselineStore {
        var inner: MemoryAcuityPlanBaselineStore
        var cache: TTLCache<AcuityPlanBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanBaselineStore, cache: TTLCache<AcuityPlanBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanBaseline? {
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

        func save(_ item: AcuityPlanBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanBaseline] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanBaselineStore(_ inner: MemoryAcuityPlanBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanBaselineStore {
        return CachedAcuityPlanBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan baselines. Empty fields match all.
    final class AcuityPlanBaselineQuery {
        var country: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRetries: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanBaseline) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanBaseline]) -> [AcuityPlanBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanBaselines(_ store: any AcuityPlanBaselineStore, query: AcuityPlanBaselineQuery) -> [AcuityPlanBaseline] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy eligibility baselines by code.
    protocol LegacyEligibilityBaselineStore {
        func find(_ code: String) -> LegacyEligibilityBaseline?
        func save(_ item: LegacyEligibilityBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyEligibilityBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyEligibilityBaselineStore: LegacyEligibilityBaselineStore {
        var items: [String: LegacyEligibilityBaseline]
        var order: [String]

        init(items: [String: LegacyEligibilityBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyEligibilityBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyEligibilityBaseline) {
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

        func list() -> [LegacyEligibilityBaseline] {
            var out: [LegacyEligibilityBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyEligibilityBaselineStore() -> any LegacyEligibilityBaselineStore {
        return MemoryLegacyEligibilityBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyEligibilityBaselineStore: LegacyEligibilityBaselineStore {
        var inner: MemoryLegacyEligibilityBaselineStore
        var cache: TTLCache<LegacyEligibilityBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyEligibilityBaselineStore, cache: TTLCache<LegacyEligibilityBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyEligibilityBaseline? {
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

        func save(_ item: LegacyEligibilityBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyEligibilityBaseline] {
            return inner.list()
        }
    }

    static func newCachedLegacyEligibilityBaselineStore(_ inner: MemoryLegacyEligibilityBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyEligibilityBaselineStore {
        return CachedLegacyEligibilityBaselineStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy eligibility baselines. Empty fields match all.
    final class LegacyEligibilityBaselineQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyEligibilityBaseline) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyEligibilityBaseline]) -> [LegacyEligibilityBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyEligibilityBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyEligibilityBaselines(_ store: any LegacyEligibilityBaselineStore, query: LegacyEligibilityBaselineQuery) -> [LegacyEligibilityBaseline] {
        return query.apply(store.list())
    }
}

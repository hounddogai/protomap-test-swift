import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback shift baselines by code.
    protocol FallbackShiftBaselineStore {
        func find(_ code: String) -> FallbackShiftBaseline?
        func save(_ item: FallbackShiftBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackShiftBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackShiftBaselineStore: FallbackShiftBaselineStore {
        var items: [String: FallbackShiftBaseline]
        var order: [String]

        init(items: [String: FallbackShiftBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackShiftBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackShiftBaseline) {
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

        func list() -> [FallbackShiftBaseline] {
            var out: [FallbackShiftBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackShiftBaselineStore() -> any FallbackShiftBaselineStore {
        return MemoryFallbackShiftBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackShiftBaselineStore: FallbackShiftBaselineStore {
        var inner: MemoryFallbackShiftBaselineStore
        var cache: TTLCache<FallbackShiftBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackShiftBaselineStore, cache: TTLCache<FallbackShiftBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackShiftBaseline? {
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

        func save(_ item: FallbackShiftBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackShiftBaseline] {
            return inner.list()
        }
    }

    static func newCachedFallbackShiftBaselineStore(_ inner: MemoryFallbackShiftBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackShiftBaselineStore {
        return CachedFallbackShiftBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback shift baselines. Empty fields match all.
    final class FallbackShiftBaselineQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackShiftBaseline) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackShiftBaseline]) -> [FallbackShiftBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackShiftBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackShiftBaselines(_ store: any FallbackShiftBaselineStore, query: FallbackShiftBaselineQuery) -> [FallbackShiftBaseline] {
        return query.apply(store.list())
    }
}

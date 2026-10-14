import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial baselines by code.
    protocol FallbackDenialBaselineStore {
        func find(_ code: String) -> FallbackDenialBaseline?
        func save(_ item: FallbackDenialBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialBaselineStore: FallbackDenialBaselineStore {
        var items: [String: FallbackDenialBaseline]
        var order: [String]

        init(items: [String: FallbackDenialBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialBaseline) {
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

        func list() -> [FallbackDenialBaseline] {
            var out: [FallbackDenialBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialBaselineStore() -> any FallbackDenialBaselineStore {
        return MemoryFallbackDenialBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialBaselineStore: FallbackDenialBaselineStore {
        var inner: MemoryFallbackDenialBaselineStore
        var cache: TTLCache<FallbackDenialBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialBaselineStore, cache: TTLCache<FallbackDenialBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialBaseline? {
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

        func save(_ item: FallbackDenialBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialBaseline] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialBaselineStore(_ inner: MemoryFallbackDenialBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialBaselineStore {
        return CachedFallbackDenialBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial baselines. Empty fields match all.
    final class FallbackDenialBaselineQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialBaseline) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDenialBaseline]) -> [FallbackDenialBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialBaselines(_ store: any FallbackDenialBaselineStore, query: FallbackDenialBaselineQuery) -> [FallbackDenialBaseline] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback program variances by code.
    protocol FallbackProgramVarianceStore {
        func find(_ code: String) -> FallbackProgramVariance?
        func save(_ item: FallbackProgramVariance)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackProgramVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackProgramVarianceStore: FallbackProgramVarianceStore {
        var items: [String: FallbackProgramVariance]
        var order: [String]

        init(items: [String: FallbackProgramVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackProgramVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackProgramVariance) {
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

        func list() -> [FallbackProgramVariance] {
            var out: [FallbackProgramVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackProgramVarianceStore() -> any FallbackProgramVarianceStore {
        return MemoryFallbackProgramVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackProgramVarianceStore: FallbackProgramVarianceStore {
        var inner: MemoryFallbackProgramVarianceStore
        var cache: TTLCache<FallbackProgramVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackProgramVarianceStore, cache: TTLCache<FallbackProgramVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackProgramVariance? {
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

        func save(_ item: FallbackProgramVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackProgramVariance] {
            return inner.list()
        }
    }

    static func newCachedFallbackProgramVarianceStore(_ inner: MemoryFallbackProgramVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackProgramVarianceStore {
        return CachedFallbackProgramVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback program variances. Empty fields match all.
    final class FallbackProgramVarianceQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackProgramVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackProgramVariance]) -> [FallbackProgramVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackProgramVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackProgramVariances(_ store: any FallbackProgramVarianceStore, query: FallbackProgramVarianceQuery) -> [FallbackProgramVariance] {
        return query.apply(store.list())
    }
}

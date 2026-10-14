import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback follow up baselines by code.
    protocol FallbackFollowUpBaselineStore {
        func find(_ code: String) -> FallbackFollowUpBaseline?
        func save(_ item: FallbackFollowUpBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFollowUpBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFollowUpBaselineStore: FallbackFollowUpBaselineStore {
        var items: [String: FallbackFollowUpBaseline]
        var order: [String]

        init(items: [String: FallbackFollowUpBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFollowUpBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFollowUpBaseline) {
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

        func list() -> [FallbackFollowUpBaseline] {
            var out: [FallbackFollowUpBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFollowUpBaselineStore() -> any FallbackFollowUpBaselineStore {
        return MemoryFallbackFollowUpBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFollowUpBaselineStore: FallbackFollowUpBaselineStore {
        var inner: MemoryFallbackFollowUpBaselineStore
        var cache: TTLCache<FallbackFollowUpBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFollowUpBaselineStore, cache: TTLCache<FallbackFollowUpBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFollowUpBaseline? {
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

        func save(_ item: FallbackFollowUpBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFollowUpBaseline] {
            return inner.list()
        }
    }

    static func newCachedFallbackFollowUpBaselineStore(_ inner: MemoryFallbackFollowUpBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFollowUpBaselineStore {
        return CachedFallbackFollowUpBaselineStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback follow up baselines. Empty fields match all.
    final class FallbackFollowUpBaselineQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFollowUpBaseline) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFollowUpBaseline]) -> [FallbackFollowUpBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFollowUpBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFollowUpBaselines(_ store: any FallbackFollowUpBaselineStore, query: FallbackFollowUpBaselineQuery) -> [FallbackFollowUpBaseline] {
        return query.apply(store.list())
    }
}

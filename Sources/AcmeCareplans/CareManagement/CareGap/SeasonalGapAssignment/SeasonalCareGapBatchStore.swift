import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps seasonal care gap batches by code.
    protocol SeasonalCareGapBatchStore {
        func find(_ code: String) -> SeasonalCareGapBatch?
        func save(_ item: SeasonalCareGapBatch)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalCareGapBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalCareGapBatchStore: SeasonalCareGapBatchStore {
        var items: [String: SeasonalCareGapBatch]
        var order: [String]

        init(items: [String: SeasonalCareGapBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalCareGapBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalCareGapBatch) {
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

        func list() -> [SeasonalCareGapBatch] {
            var out: [SeasonalCareGapBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalCareGapBatchStore() -> any SeasonalCareGapBatchStore {
        return MemorySeasonalCareGapBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalCareGapBatchStore: SeasonalCareGapBatchStore {
        var inner: MemorySeasonalCareGapBatchStore
        var cache: TTLCache<SeasonalCareGapBatch>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalCareGapBatchStore, cache: TTLCache<SeasonalCareGapBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalCareGapBatch? {
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

        func save(_ item: SeasonalCareGapBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalCareGapBatch] {
            return inner.list()
        }
    }

    static func newCachedSeasonalCareGapBatchStore(_ inner: MemorySeasonalCareGapBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalCareGapBatchStore {
        return CachedSeasonalCareGapBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal care gap batches. Empty fields match all.
    final class SeasonalCareGapBatchQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalCareGapBatch) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SeasonalCareGapBatch]) -> [SeasonalCareGapBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalCareGapBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalCareGapBatches(_ store: any SeasonalCareGapBatchStore, query: SeasonalCareGapBatchQuery) -> [SeasonalCareGapBatch] {
        return query.apply(store.list())
    }
}

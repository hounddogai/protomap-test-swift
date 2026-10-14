import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result variances by code.
    protocol ResultVarianceStore {
        func find(_ code: String) -> ResultVariance?
        func save(_ item: ResultVariance)
        func remove(_ code: String) -> Bool
        func list() -> [ResultVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultVarianceStore: ResultVarianceStore {
        var items: [String: ResultVariance]
        var order: [String]

        init(items: [String: ResultVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultVariance) {
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

        func list() -> [ResultVariance] {
            var out: [ResultVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultVarianceStore() -> any ResultVarianceStore {
        return MemoryResultVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultVarianceStore: ResultVarianceStore {
        var inner: MemoryResultVarianceStore
        var cache: TTLCache<ResultVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultVarianceStore, cache: TTLCache<ResultVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultVariance? {
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

        func save(_ item: ResultVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultVariance] {
            return inner.list()
        }
    }

    static func newCachedResultVarianceStore(_ inner: MemoryResultVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultVarianceStore {
        return CachedResultVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result variances. Empty fields match all.
    final class ResultVarianceQuery {
        var source: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultVariance) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ResultVariance]) -> [ResultVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultVariances(_ store: any ResultVarianceStore, query: ResultVarianceQuery) -> [ResultVariance] {
        return query.apply(store.list())
    }
}

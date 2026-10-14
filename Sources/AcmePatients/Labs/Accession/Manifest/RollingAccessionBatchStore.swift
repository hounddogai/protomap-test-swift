import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling accession batches by code.
    protocol RollingAccessionBatchStore {
        func find(_ code: String) -> RollingAccessionBatch?
        func save(_ item: RollingAccessionBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAccessionBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAccessionBatchStore: RollingAccessionBatchStore {
        var items: [String: RollingAccessionBatch]
        var order: [String]

        init(items: [String: RollingAccessionBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAccessionBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAccessionBatch) {
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

        func list() -> [RollingAccessionBatch] {
            var out: [RollingAccessionBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAccessionBatchStore() -> any RollingAccessionBatchStore {
        return MemoryRollingAccessionBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAccessionBatchStore: RollingAccessionBatchStore {
        var inner: MemoryRollingAccessionBatchStore
        var cache: TTLCache<RollingAccessionBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAccessionBatchStore, cache: TTLCache<RollingAccessionBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAccessionBatch? {
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

        func save(_ item: RollingAccessionBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAccessionBatch] {
            return inner.list()
        }
    }

    static func newCachedRollingAccessionBatchStore(_ inner: MemoryRollingAccessionBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAccessionBatchStore {
        return CachedRollingAccessionBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling accession batches. Empty fields match all.
    final class RollingAccessionBatchQuery {
        var segment: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMargin: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAccessionBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RollingAccessionBatch]) -> [RollingAccessionBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAccessionBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAccessionBatches(_ store: any RollingAccessionBatchStore, query: RollingAccessionBatchQuery) -> [RollingAccessionBatch] {
        return query.apply(store.list())
    }
}

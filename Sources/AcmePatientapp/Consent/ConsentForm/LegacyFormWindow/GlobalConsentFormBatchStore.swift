import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global consent form batches by code.
    protocol GlobalConsentFormBatchStore {
        func find(_ code: String) -> GlobalConsentFormBatch?
        func save(_ item: GlobalConsentFormBatch)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalConsentFormBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalConsentFormBatchStore: GlobalConsentFormBatchStore {
        var items: [String: GlobalConsentFormBatch]
        var order: [String]

        init(items: [String: GlobalConsentFormBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalConsentFormBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalConsentFormBatch) {
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

        func list() -> [GlobalConsentFormBatch] {
            var out: [GlobalConsentFormBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalConsentFormBatchStore() -> any GlobalConsentFormBatchStore {
        return MemoryGlobalConsentFormBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalConsentFormBatchStore: GlobalConsentFormBatchStore {
        var inner: MemoryGlobalConsentFormBatchStore
        var cache: TTLCache<GlobalConsentFormBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalConsentFormBatchStore, cache: TTLCache<GlobalConsentFormBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalConsentFormBatch? {
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

        func save(_ item: GlobalConsentFormBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalConsentFormBatch] {
            return inner.list()
        }
    }

    static func newCachedGlobalConsentFormBatchStore(_ inner: MemoryGlobalConsentFormBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalConsentFormBatchStore {
        return CachedGlobalConsentFormBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global consent form batches. Empty fields match all.
    final class GlobalConsentFormBatchQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalConsentFormBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalConsentFormBatch]) -> [GlobalConsentFormBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalConsentFormBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalConsentFormBatches(_ store: any GlobalConsentFormBatchStore, query: GlobalConsentFormBatchQuery) -> [GlobalConsentFormBatch] {
        return query.apply(store.list())
    }
}

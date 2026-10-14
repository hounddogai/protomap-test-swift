import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional slot batches by code.
    protocol RegionalSlotBatchStore {
        func find(_ code: String) -> RegionalSlotBatch?
        func save(_ item: RegionalSlotBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSlotBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSlotBatchStore: RegionalSlotBatchStore {
        var items: [String: RegionalSlotBatch]
        var order: [String]

        init(items: [String: RegionalSlotBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSlotBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSlotBatch) {
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

        func list() -> [RegionalSlotBatch] {
            var out: [RegionalSlotBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSlotBatchStore() -> any RegionalSlotBatchStore {
        return MemoryRegionalSlotBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSlotBatchStore: RegionalSlotBatchStore {
        var inner: MemoryRegionalSlotBatchStore
        var cache: TTLCache<RegionalSlotBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSlotBatchStore, cache: TTLCache<RegionalSlotBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSlotBatch? {
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

        func save(_ item: RegionalSlotBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSlotBatch] {
            return inner.list()
        }
    }

    static func newCachedRegionalSlotBatchStore(_ inner: MemoryRegionalSlotBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSlotBatchStore {
        return CachedRegionalSlotBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional slot batches. Empty fields match all.
    final class RegionalSlotBatchQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSlotBatch) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSlotBatch]) -> [RegionalSlotBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSlotBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSlotBatches(_ store: any RegionalSlotBatchStore, query: RegionalSlotBatchQuery) -> [RegionalSlotBatch] {
        return query.apply(store.list())
    }
}

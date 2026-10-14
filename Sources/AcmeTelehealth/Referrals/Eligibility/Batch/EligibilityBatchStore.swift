import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility batches by code.
    protocol EligibilityBatchStore {
        func find(_ code: String) -> EligibilityBatch?
        func save(_ item: EligibilityBatch)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityBatchStore: EligibilityBatchStore {
        var items: [String: EligibilityBatch]
        var order: [String]

        init(items: [String: EligibilityBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityBatch) {
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

        func list() -> [EligibilityBatch] {
            var out: [EligibilityBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityBatchStore() -> any EligibilityBatchStore {
        return MemoryEligibilityBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityBatchStore: EligibilityBatchStore {
        var inner: MemoryEligibilityBatchStore
        var cache: TTLCache<EligibilityBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityBatchStore, cache: TTLCache<EligibilityBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityBatch? {
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

        func save(_ item: EligibilityBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityBatch] {
            return inner.list()
        }
    }

    static func newCachedEligibilityBatchStore(_ inner: MemoryEligibilityBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityBatchStore {
        return CachedEligibilityBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility batches. Empty fields match all.
    final class EligibilityBatchQuery {
        var country: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRefills: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityBatch) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityBatch]) -> [EligibilityBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityBatches(_ store: any EligibilityBatchStore, query: EligibilityBatchQuery) -> [EligibilityBatch] {
        return query.apply(store.list())
    }
}

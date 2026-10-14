import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched census agreements by code.
    protocol BatchedCensusAgreementStore {
        func find(_ code: String) -> BatchedCensusAgreement?
        func save(_ item: BatchedCensusAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCensusAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCensusAgreementStore: BatchedCensusAgreementStore {
        var items: [String: BatchedCensusAgreement]
        var order: [String]

        init(items: [String: BatchedCensusAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCensusAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCensusAgreement) {
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

        func list() -> [BatchedCensusAgreement] {
            var out: [BatchedCensusAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCensusAgreementStore() -> any BatchedCensusAgreementStore {
        return MemoryBatchedCensusAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCensusAgreementStore: BatchedCensusAgreementStore {
        var inner: MemoryBatchedCensusAgreementStore
        var cache: TTLCache<BatchedCensusAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCensusAgreementStore, cache: TTLCache<BatchedCensusAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCensusAgreement? {
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

        func save(_ item: BatchedCensusAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCensusAgreement] {
            return inner.list()
        }
    }

    static func newCachedBatchedCensusAgreementStore(_ inner: MemoryBatchedCensusAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCensusAgreementStore {
        return CachedBatchedCensusAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched census agreements. Empty fields match all.
    final class BatchedCensusAgreementQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCensusAgreement) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCensusAgreement]) -> [BatchedCensusAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCensusAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCensusAgreements(_ store: any BatchedCensusAgreementStore, query: BatchedCensusAgreementQuery) -> [BatchedCensusAgreement] {
        return query.apply(store.list())
    }
}

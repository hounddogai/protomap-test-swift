import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness notices by code.
    protocol BatchedWitnessNoticeStore {
        func find(_ code: String) -> BatchedWitnessNotice?
        func save(_ item: BatchedWitnessNotice)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessNoticeStore: BatchedWitnessNoticeStore {
        var items: [String: BatchedWitnessNotice]
        var order: [String]

        init(items: [String: BatchedWitnessNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessNotice) {
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

        func list() -> [BatchedWitnessNotice] {
            var out: [BatchedWitnessNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessNoticeStore() -> any BatchedWitnessNoticeStore {
        return MemoryBatchedWitnessNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessNoticeStore: BatchedWitnessNoticeStore {
        var inner: MemoryBatchedWitnessNoticeStore
        var cache: TTLCache<BatchedWitnessNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessNoticeStore, cache: TTLCache<BatchedWitnessNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessNotice? {
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

        func save(_ item: BatchedWitnessNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessNotice] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessNoticeStore(_ inner: MemoryBatchedWitnessNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessNoticeStore {
        return CachedBatchedWitnessNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness notices. Empty fields match all.
    final class BatchedWitnessNoticeQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessNotice]) -> [BatchedWitnessNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessNotices(_ store: any BatchedWitnessNoticeStore, query: BatchedWitnessNoticeQuery) -> [BatchedWitnessNotice] {
        return query.apply(store.list())
    }
}

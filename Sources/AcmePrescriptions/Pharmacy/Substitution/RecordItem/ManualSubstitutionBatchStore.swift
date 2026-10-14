import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual substitution batches by code.
    protocol ManualSubstitutionBatchStore {
        func find(_ code: String) -> ManualSubstitutionBatch?
        func save(_ item: ManualSubstitutionBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSubstitutionBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSubstitutionBatchStore: ManualSubstitutionBatchStore {
        var items: [String: ManualSubstitutionBatch]
        var order: [String]

        init(items: [String: ManualSubstitutionBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSubstitutionBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSubstitutionBatch) {
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

        func list() -> [ManualSubstitutionBatch] {
            var out: [ManualSubstitutionBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSubstitutionBatchStore() -> any ManualSubstitutionBatchStore {
        return MemoryManualSubstitutionBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSubstitutionBatchStore: ManualSubstitutionBatchStore {
        var inner: MemoryManualSubstitutionBatchStore
        var cache: TTLCache<ManualSubstitutionBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSubstitutionBatchStore, cache: TTLCache<ManualSubstitutionBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSubstitutionBatch? {
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

        func save(_ item: ManualSubstitutionBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSubstitutionBatch] {
            return inner.list()
        }
    }

    static func newCachedManualSubstitutionBatchStore(_ inner: MemoryManualSubstitutionBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSubstitutionBatchStore {
        return CachedManualSubstitutionBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual substitution batches. Empty fields match all.
    final class ManualSubstitutionBatchQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSubstitutionBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSubstitutionBatch]) -> [ManualSubstitutionBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSubstitutionBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSubstitutionBatches(_ store: any ManualSubstitutionBatchStore, query: ManualSubstitutionBatchQuery) -> [ManualSubstitutionBatch] {
        return query.apply(store.list())
    }
}

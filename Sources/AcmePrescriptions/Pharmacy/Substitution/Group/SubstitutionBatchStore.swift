import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution batches by code.
    protocol SubstitutionBatchStore {
        func find(_ code: String) -> SubstitutionBatch?
        func save(_ item: SubstitutionBatch)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionBatchStore: SubstitutionBatchStore {
        var items: [String: SubstitutionBatch]
        var order: [String]

        init(items: [String: SubstitutionBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionBatch) {
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

        func list() -> [SubstitutionBatch] {
            var out: [SubstitutionBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionBatchStore() -> any SubstitutionBatchStore {
        return MemorySubstitutionBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionBatchStore: SubstitutionBatchStore {
        var inner: MemorySubstitutionBatchStore
        var cache: TTLCache<SubstitutionBatch>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionBatchStore, cache: TTLCache<SubstitutionBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionBatch? {
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

        func save(_ item: SubstitutionBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionBatch] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionBatchStore(_ inner: MemorySubstitutionBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionBatchStore {
        return CachedSubstitutionBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution batches. Empty fields match all.
    final class SubstitutionBatchQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionBatch]) -> [SubstitutionBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionBatches(_ store: any SubstitutionBatchStore, query: SubstitutionBatchQuery) -> [SubstitutionBatch] {
        return query.apply(store.list())
    }
}

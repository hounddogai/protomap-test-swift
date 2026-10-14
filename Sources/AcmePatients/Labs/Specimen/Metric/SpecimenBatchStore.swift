import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen batches by code.
    protocol SpecimenBatchStore {
        func find(_ code: String) -> SpecimenBatch?
        func save(_ item: SpecimenBatch)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenBatchStore: SpecimenBatchStore {
        var items: [String: SpecimenBatch]
        var order: [String]

        init(items: [String: SpecimenBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenBatch) {
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

        func list() -> [SpecimenBatch] {
            var out: [SpecimenBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenBatchStore() -> any SpecimenBatchStore {
        return MemorySpecimenBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenBatchStore: SpecimenBatchStore {
        var inner: MemorySpecimenBatchStore
        var cache: TTLCache<SpecimenBatch>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenBatchStore, cache: TTLCache<SpecimenBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenBatch? {
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

        func save(_ item: SpecimenBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenBatch] {
            return inner.list()
        }
    }

    static func newCachedSpecimenBatchStore(_ inner: MemorySpecimenBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenBatchStore {
        return CachedSpecimenBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen batches. Empty fields match all.
    final class SpecimenBatchQuery {
        var source: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenBatch) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenBatch]) -> [SpecimenBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenBatches(_ store: any SpecimenBatchStore, query: SpecimenBatchQuery) -> [SpecimenBatch] {
        return query.apply(store.list())
    }
}

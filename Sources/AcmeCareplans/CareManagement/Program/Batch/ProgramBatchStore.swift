import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program batches by code.
    protocol ProgramBatchStore {
        func find(_ code: String) -> ProgramBatch?
        func save(_ item: ProgramBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramBatchStore: ProgramBatchStore {
        var items: [String: ProgramBatch]
        var order: [String]

        init(items: [String: ProgramBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramBatch) {
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

        func list() -> [ProgramBatch] {
            var out: [ProgramBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramBatchStore() -> any ProgramBatchStore {
        return MemoryProgramBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramBatchStore: ProgramBatchStore {
        var inner: MemoryProgramBatchStore
        var cache: TTLCache<ProgramBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramBatchStore, cache: TTLCache<ProgramBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramBatch? {
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

        func save(_ item: ProgramBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramBatch] {
            return inner.list()
        }
    }

    static func newCachedProgramBatchStore(_ inner: MemoryProgramBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramBatchStore {
        return CachedProgramBatchStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program batches. Empty fields match all.
    final class ProgramBatchQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramBatch) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ProgramBatch]) -> [ProgramBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramBatches(_ store: any ProgramBatchStore, query: ProgramBatchQuery) -> [ProgramBatch] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling program batches by code.
    protocol RollingProgramBatchStore {
        func find(_ code: String) -> RollingProgramBatch?
        func save(_ item: RollingProgramBatch)
        func remove(_ code: String) -> Bool
        func list() -> [RollingProgramBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingProgramBatchStore: RollingProgramBatchStore {
        var items: [String: RollingProgramBatch]
        var order: [String]

        init(items: [String: RollingProgramBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingProgramBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingProgramBatch) {
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

        func list() -> [RollingProgramBatch] {
            var out: [RollingProgramBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingProgramBatchStore() -> any RollingProgramBatchStore {
        return MemoryRollingProgramBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingProgramBatchStore: RollingProgramBatchStore {
        var inner: MemoryRollingProgramBatchStore
        var cache: TTLCache<RollingProgramBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingProgramBatchStore, cache: TTLCache<RollingProgramBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingProgramBatch? {
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

        func save(_ item: RollingProgramBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingProgramBatch] {
            return inner.list()
        }
    }

    static func newCachedRollingProgramBatchStore(_ inner: MemoryRollingProgramBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingProgramBatchStore {
        return CachedRollingProgramBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling program batches. Empty fields match all.
    final class RollingProgramBatchQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingProgramBatch) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingProgramBatch]) -> [RollingProgramBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingProgramBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingProgramBatches(_ store: any RollingProgramBatchStore, query: RollingProgramBatchQuery) -> [RollingProgramBatch] {
        return query.apply(store.list())
    }
}

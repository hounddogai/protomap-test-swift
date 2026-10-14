import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched skill mix cycles by code.
    protocol BatchedSkillMixCycleStore {
        func find(_ code: String) -> BatchedSkillMixCycle?
        func save(_ item: BatchedSkillMixCycle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSkillMixCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSkillMixCycleStore: BatchedSkillMixCycleStore {
        var items: [String: BatchedSkillMixCycle]
        var order: [String]

        init(items: [String: BatchedSkillMixCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSkillMixCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSkillMixCycle) {
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

        func list() -> [BatchedSkillMixCycle] {
            var out: [BatchedSkillMixCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSkillMixCycleStore() -> any BatchedSkillMixCycleStore {
        return MemoryBatchedSkillMixCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSkillMixCycleStore: BatchedSkillMixCycleStore {
        var inner: MemoryBatchedSkillMixCycleStore
        var cache: TTLCache<BatchedSkillMixCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSkillMixCycleStore, cache: TTLCache<BatchedSkillMixCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSkillMixCycle? {
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

        func save(_ item: BatchedSkillMixCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSkillMixCycle] {
            return inner.list()
        }
    }

    static func newCachedBatchedSkillMixCycleStore(_ inner: MemoryBatchedSkillMixCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSkillMixCycleStore {
        return CachedBatchedSkillMixCycleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched skill mix cycles. Empty fields match all.
    final class BatchedSkillMixCycleQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSkillMixCycle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSkillMixCycle]) -> [BatchedSkillMixCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSkillMixCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSkillMixCycles(_ store: any BatchedSkillMixCycleStore, query: BatchedSkillMixCycleQuery) -> [BatchedSkillMixCycle] {
        return query.apply(store.list())
    }
}

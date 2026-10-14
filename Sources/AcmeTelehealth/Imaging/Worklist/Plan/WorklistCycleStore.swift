import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist cycles by code.
    protocol WorklistCycleStore {
        func find(_ code: String) -> WorklistCycle?
        func save(_ item: WorklistCycle)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistCycleStore: WorklistCycleStore {
        var items: [String: WorklistCycle]
        var order: [String]

        init(items: [String: WorklistCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistCycle) {
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

        func list() -> [WorklistCycle] {
            var out: [WorklistCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistCycleStore() -> any WorklistCycleStore {
        return MemoryWorklistCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistCycleStore: WorklistCycleStore {
        var inner: MemoryWorklistCycleStore
        var cache: TTLCache<WorklistCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistCycleStore, cache: TTLCache<WorklistCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistCycle? {
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

        func save(_ item: WorklistCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistCycle] {
            return inner.list()
        }
    }

    static func newCachedWorklistCycleStore(_ inner: MemoryWorklistCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistCycleStore {
        return CachedWorklistCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist cycles. Empty fields match all.
    final class WorklistCycleQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistCycle]) -> [WorklistCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistCycles(_ store: any WorklistCycleStore, query: WorklistCycleQuery) -> [WorklistCycle] {
        return query.apply(store.list())
    }
}

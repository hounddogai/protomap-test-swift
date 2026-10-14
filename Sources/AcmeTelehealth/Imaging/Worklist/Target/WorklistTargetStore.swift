import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist targets by code.
    protocol WorklistTargetStore {
        func find(_ code: String) -> WorklistTarget?
        func save(_ item: WorklistTarget)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistTargetStore: WorklistTargetStore {
        var items: [String: WorklistTarget]
        var order: [String]

        init(items: [String: WorklistTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistTarget) {
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

        func list() -> [WorklistTarget] {
            var out: [WorklistTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistTargetStore() -> any WorklistTargetStore {
        return MemoryWorklistTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistTargetStore: WorklistTargetStore {
        var inner: MemoryWorklistTargetStore
        var cache: TTLCache<WorklistTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistTargetStore, cache: TTLCache<WorklistTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistTarget? {
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

        func save(_ item: WorklistTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistTarget] {
            return inner.list()
        }
    }

    static func newCachedWorklistTargetStore(_ inner: MemoryWorklistTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistTargetStore {
        return CachedWorklistTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist targets. Empty fields match all.
    final class WorklistTargetQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [WorklistTarget]) -> [WorklistTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistTargets(_ store: any WorklistTargetStore, query: WorklistTargetQuery) -> [WorklistTarget] {
        return query.apply(store.list())
    }
}

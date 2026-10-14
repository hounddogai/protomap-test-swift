import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task requests by code.
    protocol TaskRequestStore {
        func find(_ code: String) -> TaskRequest?
        func save(_ item: TaskRequest)
        func remove(_ code: String) -> Bool
        func list() -> [TaskRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskRequestStore: TaskRequestStore {
        var items: [String: TaskRequest]
        var order: [String]

        init(items: [String: TaskRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskRequest) {
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

        func list() -> [TaskRequest] {
            var out: [TaskRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskRequestStore() -> any TaskRequestStore {
        return MemoryTaskRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskRequestStore: TaskRequestStore {
        var inner: MemoryTaskRequestStore
        var cache: TTLCache<TaskRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskRequestStore, cache: TTLCache<TaskRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskRequest? {
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

        func save(_ item: TaskRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskRequest] {
            return inner.list()
        }
    }

    static func newCachedTaskRequestStore(_ inner: MemoryTaskRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskRequestStore {
        return CachedTaskRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task requests. Empty fields match all.
    final class TaskRequestQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskRequest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [TaskRequest]) -> [TaskRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskRequests(_ store: any TaskRequestStore, query: TaskRequestQuery) -> [TaskRequest] {
        return query.apply(store.list())
    }
}

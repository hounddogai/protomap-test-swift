import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist requests by code.
    protocol WorklistRequestStore {
        func find(_ code: String) -> WorklistRequest?
        func save(_ item: WorklistRequest)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistRequestStore: WorklistRequestStore {
        var items: [String: WorklistRequest]
        var order: [String]

        init(items: [String: WorklistRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistRequest) {
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

        func list() -> [WorklistRequest] {
            var out: [WorklistRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistRequestStore() -> any WorklistRequestStore {
        return MemoryWorklistRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistRequestStore: WorklistRequestStore {
        var inner: MemoryWorklistRequestStore
        var cache: TTLCache<WorklistRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistRequestStore, cache: TTLCache<WorklistRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistRequest? {
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

        func save(_ item: WorklistRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistRequest] {
            return inner.list()
        }
    }

    static func newCachedWorklistRequestStore(_ inner: MemoryWorklistRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistRequestStore {
        return CachedWorklistRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist requests. Empty fields match all.
    final class WorklistRequestQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistRequest]) -> [WorklistRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistRequests(_ store: any WorklistRequestStore, query: WorklistRequestQuery) -> [WorklistRequest] {
        return query.apply(store.list())
    }
}

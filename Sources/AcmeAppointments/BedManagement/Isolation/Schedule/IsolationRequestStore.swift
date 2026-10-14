import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation requests by code.
    protocol IsolationRequestStore {
        func find(_ code: String) -> IsolationRequest?
        func save(_ item: IsolationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationRequestStore: IsolationRequestStore {
        var items: [String: IsolationRequest]
        var order: [String]

        init(items: [String: IsolationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationRequest) {
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

        func list() -> [IsolationRequest] {
            var out: [IsolationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationRequestStore() -> any IsolationRequestStore {
        return MemoryIsolationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationRequestStore: IsolationRequestStore {
        var inner: MemoryIsolationRequestStore
        var cache: TTLCache<IsolationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationRequestStore, cache: TTLCache<IsolationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationRequest? {
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

        func save(_ item: IsolationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationRequest] {
            return inner.list()
        }
    }

    static func newCachedIsolationRequestStore(_ inner: MemoryIsolationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationRequestStore {
        return CachedIsolationRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation requests. Empty fields match all.
    final class IsolationRequestQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationRequest]) -> [IsolationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationRequests(_ store: any IsolationRequestStore, query: IsolationRequestQuery) -> [IsolationRequest] {
        return query.apply(store.list())
    }
}

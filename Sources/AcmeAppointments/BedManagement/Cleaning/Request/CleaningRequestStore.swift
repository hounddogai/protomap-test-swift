import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning requests by code.
    protocol CleaningRequestStore {
        func find(_ code: String) -> CleaningRequest?
        func save(_ item: CleaningRequest)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningRequestStore: CleaningRequestStore {
        var items: [String: CleaningRequest]
        var order: [String]

        init(items: [String: CleaningRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningRequest) {
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

        func list() -> [CleaningRequest] {
            var out: [CleaningRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningRequestStore() -> any CleaningRequestStore {
        return MemoryCleaningRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningRequestStore: CleaningRequestStore {
        var inner: MemoryCleaningRequestStore
        var cache: TTLCache<CleaningRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningRequestStore, cache: TTLCache<CleaningRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningRequest? {
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

        func save(_ item: CleaningRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningRequest] {
            return inner.list()
        }
    }

    static func newCachedCleaningRequestStore(_ inner: MemoryCleaningRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningRequestStore {
        return CachedCleaningRequestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning requests. Empty fields match all.
    final class CleaningRequestQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CleaningRequest]) -> [CleaningRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningRequests(_ store: any CleaningRequestStore, query: CleaningRequestQuery) -> [CleaningRequest] {
        return query.apply(store.list())
    }
}

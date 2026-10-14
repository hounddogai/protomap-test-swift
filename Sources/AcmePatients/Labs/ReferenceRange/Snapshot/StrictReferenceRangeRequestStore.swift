import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict reference range requests by code.
    protocol StrictReferenceRangeRequestStore {
        func find(_ code: String) -> StrictReferenceRangeRequest?
        func save(_ item: StrictReferenceRangeRequest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictReferenceRangeRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictReferenceRangeRequestStore: StrictReferenceRangeRequestStore {
        var items: [String: StrictReferenceRangeRequest]
        var order: [String]

        init(items: [String: StrictReferenceRangeRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictReferenceRangeRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictReferenceRangeRequest) {
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

        func list() -> [StrictReferenceRangeRequest] {
            var out: [StrictReferenceRangeRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictReferenceRangeRequestStore() -> any StrictReferenceRangeRequestStore {
        return MemoryStrictReferenceRangeRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictReferenceRangeRequestStore: StrictReferenceRangeRequestStore {
        var inner: MemoryStrictReferenceRangeRequestStore
        var cache: TTLCache<StrictReferenceRangeRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictReferenceRangeRequestStore, cache: TTLCache<StrictReferenceRangeRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictReferenceRangeRequest? {
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

        func save(_ item: StrictReferenceRangeRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictReferenceRangeRequest] {
            return inner.list()
        }
    }

    static func newCachedStrictReferenceRangeRequestStore(_ inner: MemoryStrictReferenceRangeRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictReferenceRangeRequestStore {
        return CachedStrictReferenceRangeRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict reference range requests. Empty fields match all.
    final class StrictReferenceRangeRequestQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictReferenceRangeRequest) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictReferenceRangeRequest]) -> [StrictReferenceRangeRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictReferenceRangeRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictReferenceRangeRequests(_ store: any StrictReferenceRangeRequestStore, query: StrictReferenceRangeRequestQuery) -> [StrictReferenceRangeRequest] {
        return query.apply(store.list())
    }
}

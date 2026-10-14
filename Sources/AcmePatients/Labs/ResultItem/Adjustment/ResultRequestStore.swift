import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result requests by code.
    protocol ResultRequestStore {
        func find(_ code: String) -> ResultRequest?
        func save(_ item: ResultRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ResultRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultRequestStore: ResultRequestStore {
        var items: [String: ResultRequest]
        var order: [String]

        init(items: [String: ResultRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultRequest) {
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

        func list() -> [ResultRequest] {
            var out: [ResultRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultRequestStore() -> any ResultRequestStore {
        return MemoryResultRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultRequestStore: ResultRequestStore {
        var inner: MemoryResultRequestStore
        var cache: TTLCache<ResultRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultRequestStore, cache: TTLCache<ResultRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultRequest? {
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

        func save(_ item: ResultRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultRequest] {
            return inner.list()
        }
    }

    static func newCachedResultRequestStore(_ inner: MemoryResultRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultRequestStore {
        return CachedResultRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result requests. Empty fields match all.
    final class ResultRequestQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ResultRequest]) -> [ResultRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultRequests(_ store: any ResultRequestStore, query: ResultRequestQuery) -> [ResultRequest] {
        return query.apply(store.list())
    }
}

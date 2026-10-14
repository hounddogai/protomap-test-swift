import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps strict outreach requests by code.
    protocol StrictOutreachRequestStore {
        func find(_ code: String) -> StrictOutreachRequest?
        func save(_ item: StrictOutreachRequest)
        func remove(_ code: String) -> Bool
        func list() -> [StrictOutreachRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictOutreachRequestStore: StrictOutreachRequestStore {
        var items: [String: StrictOutreachRequest]
        var order: [String]

        init(items: [String: StrictOutreachRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictOutreachRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictOutreachRequest) {
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

        func list() -> [StrictOutreachRequest] {
            var out: [StrictOutreachRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictOutreachRequestStore() -> any StrictOutreachRequestStore {
        return MemoryStrictOutreachRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictOutreachRequestStore: StrictOutreachRequestStore {
        var inner: MemoryStrictOutreachRequestStore
        var cache: TTLCache<StrictOutreachRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictOutreachRequestStore, cache: TTLCache<StrictOutreachRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictOutreachRequest? {
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

        func save(_ item: StrictOutreachRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictOutreachRequest] {
            return inner.list()
        }
    }

    static func newCachedStrictOutreachRequestStore(_ inner: MemoryStrictOutreachRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictOutreachRequestStore {
        return CachedStrictOutreachRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict outreach requests. Empty fields match all.
    final class StrictOutreachRequestQuery {
        var name: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRetries: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictOutreachRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictOutreachRequest]) -> [StrictOutreachRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictOutreachRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictOutreachRequests(_ store: any StrictOutreachRequestStore, query: StrictOutreachRequestQuery) -> [StrictOutreachRequest] {
        return query.apply(store.list())
    }
}

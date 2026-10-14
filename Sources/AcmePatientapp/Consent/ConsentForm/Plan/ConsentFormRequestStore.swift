import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form requests by code.
    protocol ConsentFormRequestStore {
        func find(_ code: String) -> ConsentFormRequest?
        func save(_ item: ConsentFormRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormRequestStore: ConsentFormRequestStore {
        var items: [String: ConsentFormRequest]
        var order: [String]

        init(items: [String: ConsentFormRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormRequest) {
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

        func list() -> [ConsentFormRequest] {
            var out: [ConsentFormRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormRequestStore() -> any ConsentFormRequestStore {
        return MemoryConsentFormRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormRequestStore: ConsentFormRequestStore {
        var inner: MemoryConsentFormRequestStore
        var cache: TTLCache<ConsentFormRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormRequestStore, cache: TTLCache<ConsentFormRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormRequest? {
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

        func save(_ item: ConsentFormRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormRequest] {
            return inner.list()
        }
    }

    static func newCachedConsentFormRequestStore(_ inner: MemoryConsentFormRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormRequestStore {
        return CachedConsentFormRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form requests. Empty fields match all.
    final class ConsentFormRequestQuery {
        var ward: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minBudget: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormRequest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormRequest]) -> [ConsentFormRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormRequests(_ store: any ConsentFormRequestStore, query: ConsentFormRequestQuery) -> [ConsentFormRequest] {
        return query.apply(store.list())
    }
}

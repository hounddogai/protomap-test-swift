import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution requests by code.
    protocol SubstitutionRequestStore {
        func find(_ code: String) -> SubstitutionRequest?
        func save(_ item: SubstitutionRequest)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionRequestStore: SubstitutionRequestStore {
        var items: [String: SubstitutionRequest]
        var order: [String]

        init(items: [String: SubstitutionRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionRequest) {
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

        func list() -> [SubstitutionRequest] {
            var out: [SubstitutionRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionRequestStore() -> any SubstitutionRequestStore {
        return MemorySubstitutionRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionRequestStore: SubstitutionRequestStore {
        var inner: MemorySubstitutionRequestStore
        var cache: TTLCache<SubstitutionRequest>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionRequestStore, cache: TTLCache<SubstitutionRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionRequest? {
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

        func save(_ item: SubstitutionRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionRequest] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionRequestStore(_ inner: MemorySubstitutionRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionRequestStore {
        return CachedSubstitutionRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution requests. Empty fields match all.
    final class SubstitutionRequestQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionRequest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [SubstitutionRequest]) -> [SubstitutionRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionRequests(_ store: any SubstitutionRequestStore, query: SubstitutionRequestQuery) -> [SubstitutionRequest] {
        return query.apply(store.list())
    }
}

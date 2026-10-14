import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language requests by code.
    protocol LanguageRequestStore {
        func find(_ code: String) -> LanguageRequest?
        func save(_ item: LanguageRequest)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageRequestStore: LanguageRequestStore {
        var items: [String: LanguageRequest]
        var order: [String]

        init(items: [String: LanguageRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageRequest) {
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

        func list() -> [LanguageRequest] {
            var out: [LanguageRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageRequestStore() -> any LanguageRequestStore {
        return MemoryLanguageRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageRequestStore: LanguageRequestStore {
        var inner: MemoryLanguageRequestStore
        var cache: TTLCache<LanguageRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageRequestStore, cache: TTLCache<LanguageRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageRequest? {
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

        func save(_ item: LanguageRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageRequest] {
            return inner.list()
        }
    }

    static func newCachedLanguageRequestStore(_ inner: MemoryLanguageRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageRequestStore {
        return CachedLanguageRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language requests. Empty fields match all.
    final class LanguageRequestQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageRequest]) -> [LanguageRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageRequests(_ store: any LanguageRequestStore, query: LanguageRequestQuery) -> [LanguageRequest] {
        return query.apply(store.list())
    }
}

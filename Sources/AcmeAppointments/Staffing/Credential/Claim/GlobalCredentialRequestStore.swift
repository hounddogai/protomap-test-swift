import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global credential requests by code.
    protocol GlobalCredentialRequestStore {
        func find(_ code: String) -> GlobalCredentialRequest?
        func save(_ item: GlobalCredentialRequest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCredentialRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCredentialRequestStore: GlobalCredentialRequestStore {
        var items: [String: GlobalCredentialRequest]
        var order: [String]

        init(items: [String: GlobalCredentialRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCredentialRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCredentialRequest) {
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

        func list() -> [GlobalCredentialRequest] {
            var out: [GlobalCredentialRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCredentialRequestStore() -> any GlobalCredentialRequestStore {
        return MemoryGlobalCredentialRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCredentialRequestStore: GlobalCredentialRequestStore {
        var inner: MemoryGlobalCredentialRequestStore
        var cache: TTLCache<GlobalCredentialRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCredentialRequestStore, cache: TTLCache<GlobalCredentialRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCredentialRequest? {
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

        func save(_ item: GlobalCredentialRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCredentialRequest] {
            return inner.list()
        }
    }

    static func newCachedGlobalCredentialRequestStore(_ inner: MemoryGlobalCredentialRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCredentialRequestStore {
        return CachedGlobalCredentialRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global credential requests. Empty fields match all.
    final class GlobalCredentialRequestQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCredentialRequest) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCredentialRequest]) -> [GlobalCredentialRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCredentialRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCredentialRequests(_ store: any GlobalCredentialRequestStore, query: GlobalCredentialRequestQuery) -> [GlobalCredentialRequest] {
        return query.apply(store.list())
    }
}

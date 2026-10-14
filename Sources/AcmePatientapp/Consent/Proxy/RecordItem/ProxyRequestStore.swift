import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy requests by code.
    protocol ProxyRequestStore {
        func find(_ code: String) -> ProxyRequest?
        func save(_ item: ProxyRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyRequestStore: ProxyRequestStore {
        var items: [String: ProxyRequest]
        var order: [String]

        init(items: [String: ProxyRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyRequest) {
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

        func list() -> [ProxyRequest] {
            var out: [ProxyRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyRequestStore() -> any ProxyRequestStore {
        return MemoryProxyRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyRequestStore: ProxyRequestStore {
        var inner: MemoryProxyRequestStore
        var cache: TTLCache<ProxyRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyRequestStore, cache: TTLCache<ProxyRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyRequest? {
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

        func save(_ item: ProxyRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyRequest] {
            return inner.list()
        }
    }

    static func newCachedProxyRequestStore(_ inner: MemoryProxyRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyRequestStore {
        return CachedProxyRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy requests. Empty fields match all.
    final class ProxyRequestQuery {
        var facility: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyRequest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyRequest]) -> [ProxyRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyRequests(_ store: any ProxyRequestStore, query: ProxyRequestQuery) -> [ProxyRequest] {
        return query.apply(store.list())
    }
}

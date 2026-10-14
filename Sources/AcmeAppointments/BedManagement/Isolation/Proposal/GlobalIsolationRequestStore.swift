import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global isolation requests by code.
    protocol GlobalIsolationRequestStore {
        func find(_ code: String) -> GlobalIsolationRequest?
        func save(_ item: GlobalIsolationRequest)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalIsolationRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalIsolationRequestStore: GlobalIsolationRequestStore {
        var items: [String: GlobalIsolationRequest]
        var order: [String]

        init(items: [String: GlobalIsolationRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalIsolationRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalIsolationRequest) {
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

        func list() -> [GlobalIsolationRequest] {
            var out: [GlobalIsolationRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalIsolationRequestStore() -> any GlobalIsolationRequestStore {
        return MemoryGlobalIsolationRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalIsolationRequestStore: GlobalIsolationRequestStore {
        var inner: MemoryGlobalIsolationRequestStore
        var cache: TTLCache<GlobalIsolationRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalIsolationRequestStore, cache: TTLCache<GlobalIsolationRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalIsolationRequest? {
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

        func save(_ item: GlobalIsolationRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalIsolationRequest] {
            return inner.list()
        }
    }

    static func newCachedGlobalIsolationRequestStore(_ inner: MemoryGlobalIsolationRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalIsolationRequestStore {
        return CachedGlobalIsolationRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global isolation requests. Empty fields match all.
    final class GlobalIsolationRequestQuery {
        var source: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRate: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalIsolationRequest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalIsolationRequest]) -> [GlobalIsolationRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalIsolationRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalIsolationRequests(_ store: any GlobalIsolationRequestStore, query: GlobalIsolationRequestQuery) -> [GlobalIsolationRequest] {
        return query.apply(store.list())
    }
}

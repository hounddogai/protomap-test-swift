import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure requests by code.
    protocol ClosureRequestStore {
        func find(_ code: String) -> ClosureRequest?
        func save(_ item: ClosureRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureRequestStore: ClosureRequestStore {
        var items: [String: ClosureRequest]
        var order: [String]

        init(items: [String: ClosureRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureRequest) {
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

        func list() -> [ClosureRequest] {
            var out: [ClosureRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureRequestStore() -> any ClosureRequestStore {
        return MemoryClosureRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureRequestStore: ClosureRequestStore {
        var inner: MemoryClosureRequestStore
        var cache: TTLCache<ClosureRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureRequestStore, cache: TTLCache<ClosureRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureRequest? {
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

        func save(_ item: ClosureRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureRequest] {
            return inner.list()
        }
    }

    static func newCachedClosureRequestStore(_ inner: MemoryClosureRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureRequestStore {
        return CachedClosureRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure requests. Empty fields match all.
    final class ClosureRequestQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureRequest]) -> [ClosureRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureRequests(_ store: any ClosureRequestStore, query: ClosureRequestQuery) -> [ClosureRequest] {
        return query.apply(store.list())
    }
}

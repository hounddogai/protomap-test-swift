import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen requests by code.
    protocol SpecimenRequestStore {
        func find(_ code: String) -> SpecimenRequest?
        func save(_ item: SpecimenRequest)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenRequestStore: SpecimenRequestStore {
        var items: [String: SpecimenRequest]
        var order: [String]

        init(items: [String: SpecimenRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenRequest) {
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

        func list() -> [SpecimenRequest] {
            var out: [SpecimenRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenRequestStore() -> any SpecimenRequestStore {
        return MemorySpecimenRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenRequestStore: SpecimenRequestStore {
        var inner: MemorySpecimenRequestStore
        var cache: TTLCache<SpecimenRequest>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenRequestStore, cache: TTLCache<SpecimenRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenRequest? {
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

        func save(_ item: SpecimenRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenRequest] {
            return inner.list()
        }
    }

    static func newCachedSpecimenRequestStore(_ inner: MemorySpecimenRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenRequestStore {
        return CachedSpecimenRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen requests. Empty fields match all.
    final class SpecimenRequestQuery {
        var channel: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCost: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenRequest) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenRequest]) -> [SpecimenRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenRequests(_ store: any SpecimenRequestStore, query: SpecimenRequestQuery) -> [SpecimenRequest] {
        return query.apply(store.list())
    }
}

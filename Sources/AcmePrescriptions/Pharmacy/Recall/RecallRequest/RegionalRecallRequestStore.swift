import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional recall requests by code.
    protocol RegionalRecallRequestStore {
        func find(_ code: String) -> RegionalRecallRequest?
        func save(_ item: RegionalRecallRequest)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRecallRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRecallRequestStore: RegionalRecallRequestStore {
        var items: [String: RegionalRecallRequest]
        var order: [String]

        init(items: [String: RegionalRecallRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRecallRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRecallRequest) {
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

        func list() -> [RegionalRecallRequest] {
            var out: [RegionalRecallRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRecallRequestStore() -> any RegionalRecallRequestStore {
        return MemoryRegionalRecallRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRecallRequestStore: RegionalRecallRequestStore {
        var inner: MemoryRegionalRecallRequestStore
        var cache: TTLCache<RegionalRecallRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRecallRequestStore, cache: TTLCache<RegionalRecallRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRecallRequest? {
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

        func save(_ item: RegionalRecallRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRecallRequest] {
            return inner.list()
        }
    }

    static func newCachedRegionalRecallRequestStore(_ inner: MemoryRegionalRecallRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRecallRequestStore {
        return CachedRegionalRecallRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional recall requests. Empty fields match all.
    final class RegionalRecallRequestQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRecallRequest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRecallRequest]) -> [RegionalRecallRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRecallRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRecallRequests(_ store: any RegionalRecallRequestStore, query: RegionalRecallRequestQuery) -> [RegionalRecallRequest] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach requests by code.
    protocol OutreachRequestStore {
        func find(_ code: String) -> OutreachRequest?
        func save(_ item: OutreachRequest)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachRequestStore: OutreachRequestStore {
        var items: [String: OutreachRequest]
        var order: [String]

        init(items: [String: OutreachRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachRequest) {
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

        func list() -> [OutreachRequest] {
            var out: [OutreachRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachRequestStore() -> any OutreachRequestStore {
        return MemoryOutreachRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachRequestStore: OutreachRequestStore {
        var inner: MemoryOutreachRequestStore
        var cache: TTLCache<OutreachRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachRequestStore, cache: TTLCache<OutreachRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachRequest? {
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

        func save(_ item: OutreachRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachRequest] {
            return inner.list()
        }
    }

    static func newCachedOutreachRequestStore(_ inner: MemoryOutreachRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachRequestStore {
        return CachedOutreachRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach requests. Empty fields match all.
    final class OutreachRequestQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachRequest) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachRequest]) -> [OutreachRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachRequests(_ store: any OutreachRequestStore, query: OutreachRequestQuery) -> [OutreachRequest] {
        return query.apply(store.list())
    }
}

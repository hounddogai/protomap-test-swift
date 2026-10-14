import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary recall requests by code.
    protocol PrimaryRecallRequestStore {
        func find(_ code: String) -> PrimaryRecallRequest?
        func save(_ item: PrimaryRecallRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRecallRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRecallRequestStore: PrimaryRecallRequestStore {
        var items: [String: PrimaryRecallRequest]
        var order: [String]

        init(items: [String: PrimaryRecallRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRecallRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRecallRequest) {
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

        func list() -> [PrimaryRecallRequest] {
            var out: [PrimaryRecallRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRecallRequestStore() -> any PrimaryRecallRequestStore {
        return MemoryPrimaryRecallRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRecallRequestStore: PrimaryRecallRequestStore {
        var inner: MemoryPrimaryRecallRequestStore
        var cache: TTLCache<PrimaryRecallRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRecallRequestStore, cache: TTLCache<PrimaryRecallRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRecallRequest? {
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

        func save(_ item: PrimaryRecallRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRecallRequest] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRecallRequestStore(_ inner: MemoryPrimaryRecallRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRecallRequestStore {
        return CachedPrimaryRecallRequestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary recall requests. Empty fields match all.
    final class PrimaryRecallRequestQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRecallRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRecallRequest]) -> [PrimaryRecallRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRecallRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRecallRequests(_ store: any PrimaryRecallRequestStore, query: PrimaryRecallRequestQuery) -> [PrimaryRecallRequest] {
        return query.apply(store.list())
    }
}

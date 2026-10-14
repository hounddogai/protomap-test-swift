import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure requests by code.
    protocol DisclosureRequestStore {
        func find(_ code: String) -> DisclosureRequest?
        func save(_ item: DisclosureRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureRequestStore: DisclosureRequestStore {
        var items: [String: DisclosureRequest]
        var order: [String]

        init(items: [String: DisclosureRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureRequest) {
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

        func list() -> [DisclosureRequest] {
            var out: [DisclosureRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureRequestStore() -> any DisclosureRequestStore {
        return MemoryDisclosureRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureRequestStore: DisclosureRequestStore {
        var inner: MemoryDisclosureRequestStore
        var cache: TTLCache<DisclosureRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureRequestStore, cache: TTLCache<DisclosureRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureRequest? {
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

        func save(_ item: DisclosureRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureRequest] {
            return inner.list()
        }
    }

    static func newCachedDisclosureRequestStore(_ inner: MemoryDisclosureRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureRequestStore {
        return CachedDisclosureRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure requests. Empty fields match all.
    final class DisclosureRequestQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureRequest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureRequest]) -> [DisclosureRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureRequests(_ store: any DisclosureRequestStore, query: DisclosureRequestQuery) -> [DisclosureRequest] {
        return query.apply(store.list())
    }
}

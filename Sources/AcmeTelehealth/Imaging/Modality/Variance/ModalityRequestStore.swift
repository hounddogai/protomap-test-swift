import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality requests by code.
    protocol ModalityRequestStore {
        func find(_ code: String) -> ModalityRequest?
        func save(_ item: ModalityRequest)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityRequestStore: ModalityRequestStore {
        var items: [String: ModalityRequest]
        var order: [String]

        init(items: [String: ModalityRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityRequest) {
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

        func list() -> [ModalityRequest] {
            var out: [ModalityRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityRequestStore() -> any ModalityRequestStore {
        return MemoryModalityRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityRequestStore: ModalityRequestStore {
        var inner: MemoryModalityRequestStore
        var cache: TTLCache<ModalityRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityRequestStore, cache: TTLCache<ModalityRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityRequest? {
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

        func save(_ item: ModalityRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityRequest] {
            return inner.list()
        }
    }

    static func newCachedModalityRequestStore(_ inner: MemoryModalityRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityRequestStore {
        return CachedModalityRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality requests. Empty fields match all.
    final class ModalityRequestQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityRequest) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityRequest]) -> [ModalityRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityRequests(_ store: any ModalityRequestStore, query: ModalityRequestQuery) -> [ModalityRequest] {
        return query.apply(store.list())
    }
}

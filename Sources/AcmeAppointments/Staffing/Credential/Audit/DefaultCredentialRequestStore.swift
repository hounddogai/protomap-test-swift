import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default credential requests by code.
    protocol DefaultCredentialRequestStore {
        func find(_ code: String) -> DefaultCredentialRequest?
        func save(_ item: DefaultCredentialRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCredentialRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCredentialRequestStore: DefaultCredentialRequestStore {
        var items: [String: DefaultCredentialRequest]
        var order: [String]

        init(items: [String: DefaultCredentialRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCredentialRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCredentialRequest) {
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

        func list() -> [DefaultCredentialRequest] {
            var out: [DefaultCredentialRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCredentialRequestStore() -> any DefaultCredentialRequestStore {
        return MemoryDefaultCredentialRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCredentialRequestStore: DefaultCredentialRequestStore {
        var inner: MemoryDefaultCredentialRequestStore
        var cache: TTLCache<DefaultCredentialRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCredentialRequestStore, cache: TTLCache<DefaultCredentialRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCredentialRequest? {
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

        func save(_ item: DefaultCredentialRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCredentialRequest] {
            return inner.list()
        }
    }

    static func newCachedDefaultCredentialRequestStore(_ inner: MemoryDefaultCredentialRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCredentialRequestStore {
        return CachedDefaultCredentialRequestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default credential requests. Empty fields match all.
    final class DefaultCredentialRequestQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCredentialRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [DefaultCredentialRequest]) -> [DefaultCredentialRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCredentialRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCredentialRequests(_ store: any DefaultCredentialRequestStore, query: DefaultCredentialRequestQuery) -> [DefaultCredentialRequest] {
        return query.apply(store.list())
    }
}

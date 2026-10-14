import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending credential requests by code.
    protocol PendingCredentialRequestStore {
        func find(_ code: String) -> PendingCredentialRequest?
        func save(_ item: PendingCredentialRequest)
        func remove(_ code: String) -> Bool
        func list() -> [PendingCredentialRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingCredentialRequestStore: PendingCredentialRequestStore {
        var items: [String: PendingCredentialRequest]
        var order: [String]

        init(items: [String: PendingCredentialRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingCredentialRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingCredentialRequest) {
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

        func list() -> [PendingCredentialRequest] {
            var out: [PendingCredentialRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingCredentialRequestStore() -> any PendingCredentialRequestStore {
        return MemoryPendingCredentialRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingCredentialRequestStore: PendingCredentialRequestStore {
        var inner: MemoryPendingCredentialRequestStore
        var cache: TTLCache<PendingCredentialRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingCredentialRequestStore, cache: TTLCache<PendingCredentialRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingCredentialRequest? {
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

        func save(_ item: PendingCredentialRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingCredentialRequest] {
            return inner.list()
        }
    }

    static func newCachedPendingCredentialRequestStore(_ inner: MemoryPendingCredentialRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingCredentialRequestStore {
        return CachedPendingCredentialRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending credential requests. Empty fields match all.
    final class PendingCredentialRequestQuery {
        var source: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingCredentialRequest) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [PendingCredentialRequest]) -> [PendingCredentialRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingCredentialRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingCredentialRequests(_ store: any PendingCredentialRequestStore, query: PendingCredentialRequestQuery) -> [PendingCredentialRequest] {
        return query.apply(store.list())
    }
}

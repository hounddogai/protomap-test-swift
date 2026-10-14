import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default credential claims by code.
    protocol DefaultCredentialClaimStore {
        func find(_ code: String) -> DefaultCredentialClaim?
        func save(_ item: DefaultCredentialClaim)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCredentialClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCredentialClaimStore: DefaultCredentialClaimStore {
        var items: [String: DefaultCredentialClaim]
        var order: [String]

        init(items: [String: DefaultCredentialClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCredentialClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCredentialClaim) {
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

        func list() -> [DefaultCredentialClaim] {
            var out: [DefaultCredentialClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCredentialClaimStore() -> any DefaultCredentialClaimStore {
        return MemoryDefaultCredentialClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCredentialClaimStore: DefaultCredentialClaimStore {
        var inner: MemoryDefaultCredentialClaimStore
        var cache: TTLCache<DefaultCredentialClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCredentialClaimStore, cache: TTLCache<DefaultCredentialClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCredentialClaim? {
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

        func save(_ item: DefaultCredentialClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCredentialClaim] {
            return inner.list()
        }
    }

    static func newCachedDefaultCredentialClaimStore(_ inner: MemoryDefaultCredentialClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCredentialClaimStore {
        return CachedDefaultCredentialClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default credential claims. Empty fields match all.
    final class DefaultCredentialClaimQuery {
        var channel: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCredentialClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCredentialClaim]) -> [DefaultCredentialClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCredentialClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCredentialClaims(_ store: any DefaultCredentialClaimStore, query: DefaultCredentialClaimQuery) -> [DefaultCredentialClaim] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation tiers by code.
    protocol RevocationTierStore {
        func find(_ code: String) -> RevocationTier?
        func save(_ item: RevocationTier)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationTierStore: RevocationTierStore {
        var items: [String: RevocationTier]
        var order: [String]

        init(items: [String: RevocationTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationTier) {
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

        func list() -> [RevocationTier] {
            var out: [RevocationTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationTierStore() -> any RevocationTierStore {
        return MemoryRevocationTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationTierStore: RevocationTierStore {
        var inner: MemoryRevocationTierStore
        var cache: TTLCache<RevocationTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationTierStore, cache: TTLCache<RevocationTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationTier? {
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

        func save(_ item: RevocationTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationTier] {
            return inner.list()
        }
    }

    static func newCachedRevocationTierStore(_ inner: MemoryRevocationTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationTierStore {
        return CachedRevocationTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation tiers. Empty fields match all.
    final class RevocationTierQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationTier) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationTier]) -> [RevocationTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationTiers(_ store: any RevocationTierStore, query: RevocationTierQuery) -> [RevocationTier] {
        return query.apply(store.list())
    }
}

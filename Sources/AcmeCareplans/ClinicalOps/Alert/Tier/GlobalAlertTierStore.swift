import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global alert tiers by code.
    protocol GlobalAlertTierStore {
        func find(_ code: String) -> GlobalAlertTier?
        func save(_ item: GlobalAlertTier)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAlertTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAlertTierStore: GlobalAlertTierStore {
        var items: [String: GlobalAlertTier]
        var order: [String]

        init(items: [String: GlobalAlertTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAlertTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAlertTier) {
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

        func list() -> [GlobalAlertTier] {
            var out: [GlobalAlertTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAlertTierStore() -> any GlobalAlertTierStore {
        return MemoryGlobalAlertTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAlertTierStore: GlobalAlertTierStore {
        var inner: MemoryGlobalAlertTierStore
        var cache: TTLCache<GlobalAlertTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAlertTierStore, cache: TTLCache<GlobalAlertTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAlertTier? {
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

        func save(_ item: GlobalAlertTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAlertTier] {
            return inner.list()
        }
    }

    static func newCachedGlobalAlertTierStore(_ inner: MemoryGlobalAlertTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAlertTierStore {
        return CachedGlobalAlertTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global alert tiers. Empty fields match all.
    final class GlobalAlertTierQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAlertTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAlertTier]) -> [GlobalAlertTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAlertTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAlertTiers(_ store: any GlobalAlertTierStore, query: GlobalAlertTierQuery) -> [GlobalAlertTier] {
        return query.apply(store.list())
    }
}

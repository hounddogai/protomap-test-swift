import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global consent form tiers by code.
    protocol GlobalConsentFormTierStore {
        func find(_ code: String) -> GlobalConsentFormTier?
        func save(_ item: GlobalConsentFormTier)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalConsentFormTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalConsentFormTierStore: GlobalConsentFormTierStore {
        var items: [String: GlobalConsentFormTier]
        var order: [String]

        init(items: [String: GlobalConsentFormTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalConsentFormTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalConsentFormTier) {
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

        func list() -> [GlobalConsentFormTier] {
            var out: [GlobalConsentFormTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalConsentFormTierStore() -> any GlobalConsentFormTierStore {
        return MemoryGlobalConsentFormTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalConsentFormTierStore: GlobalConsentFormTierStore {
        var inner: MemoryGlobalConsentFormTierStore
        var cache: TTLCache<GlobalConsentFormTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalConsentFormTierStore, cache: TTLCache<GlobalConsentFormTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalConsentFormTier? {
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

        func save(_ item: GlobalConsentFormTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalConsentFormTier] {
            return inner.list()
        }
    }

    static func newCachedGlobalConsentFormTierStore(_ inner: MemoryGlobalConsentFormTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalConsentFormTierStore {
        return CachedGlobalConsentFormTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global consent form tiers. Empty fields match all.
    final class GlobalConsentFormTierQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalConsentFormTier) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [GlobalConsentFormTier]) -> [GlobalConsentFormTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalConsentFormTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalConsentFormTiers(_ store: any GlobalConsentFormTierStore, query: GlobalConsentFormTierQuery) -> [GlobalConsentFormTier] {
        return query.apply(store.list())
    }
}

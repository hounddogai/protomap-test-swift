import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled consent form claims by code.
    protocol ScheduledConsentFormClaimStore {
        func find(_ code: String) -> ScheduledConsentFormClaim?
        func save(_ item: ScheduledConsentFormClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledConsentFormClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledConsentFormClaimStore: ScheduledConsentFormClaimStore {
        var items: [String: ScheduledConsentFormClaim]
        var order: [String]

        init(items: [String: ScheduledConsentFormClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledConsentFormClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledConsentFormClaim) {
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

        func list() -> [ScheduledConsentFormClaim] {
            var out: [ScheduledConsentFormClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledConsentFormClaimStore() -> any ScheduledConsentFormClaimStore {
        return MemoryScheduledConsentFormClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledConsentFormClaimStore: ScheduledConsentFormClaimStore {
        var inner: MemoryScheduledConsentFormClaimStore
        var cache: TTLCache<ScheduledConsentFormClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledConsentFormClaimStore, cache: TTLCache<ScheduledConsentFormClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledConsentFormClaim? {
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

        func save(_ item: ScheduledConsentFormClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledConsentFormClaim] {
            return inner.list()
        }
    }

    static func newCachedScheduledConsentFormClaimStore(_ inner: MemoryScheduledConsentFormClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledConsentFormClaimStore {
        return CachedScheduledConsentFormClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled consent form claims. Empty fields match all.
    final class ScheduledConsentFormClaimQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledConsentFormClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledConsentFormClaim]) -> [ScheduledConsentFormClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledConsentFormClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledConsentFormClaims(_ store: any ScheduledConsentFormClaimStore, query: ScheduledConsentFormClaimQuery) -> [ScheduledConsentFormClaim] {
        return query.apply(store.list())
    }
}

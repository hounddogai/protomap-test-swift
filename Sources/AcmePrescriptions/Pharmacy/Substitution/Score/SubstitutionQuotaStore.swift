import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution quotas by code.
    protocol SubstitutionQuotaStore {
        func find(_ code: String) -> SubstitutionQuota?
        func save(_ item: SubstitutionQuota)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionQuotaStore: SubstitutionQuotaStore {
        var items: [String: SubstitutionQuota]
        var order: [String]

        init(items: [String: SubstitutionQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionQuota) {
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

        func list() -> [SubstitutionQuota] {
            var out: [SubstitutionQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionQuotaStore() -> any SubstitutionQuotaStore {
        return MemorySubstitutionQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionQuotaStore: SubstitutionQuotaStore {
        var inner: MemorySubstitutionQuotaStore
        var cache: TTLCache<SubstitutionQuota>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionQuotaStore, cache: TTLCache<SubstitutionQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionQuota? {
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

        func save(_ item: SubstitutionQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionQuota] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionQuotaStore(_ inner: MemorySubstitutionQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionQuotaStore {
        return CachedSubstitutionQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution quotas. Empty fields match all.
    final class SubstitutionQuotaQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SubstitutionQuota]) -> [SubstitutionQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionQuotas(_ store: any SubstitutionQuotaStore, query: SubstitutionQuotaQuery) -> [SubstitutionQuota] {
        return query.apply(store.list())
    }
}

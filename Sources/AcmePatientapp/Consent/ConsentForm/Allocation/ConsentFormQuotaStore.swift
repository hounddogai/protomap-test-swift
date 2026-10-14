import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form quotas by code.
    protocol ConsentFormQuotaStore {
        func find(_ code: String) -> ConsentFormQuota?
        func save(_ item: ConsentFormQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormQuotaStore: ConsentFormQuotaStore {
        var items: [String: ConsentFormQuota]
        var order: [String]

        init(items: [String: ConsentFormQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormQuota) {
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

        func list() -> [ConsentFormQuota] {
            var out: [ConsentFormQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormQuotaStore() -> any ConsentFormQuotaStore {
        return MemoryConsentFormQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormQuotaStore: ConsentFormQuotaStore {
        var inner: MemoryConsentFormQuotaStore
        var cache: TTLCache<ConsentFormQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormQuotaStore, cache: TTLCache<ConsentFormQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormQuota? {
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

        func save(_ item: ConsentFormQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormQuota] {
            return inner.list()
        }
    }

    static func newCachedConsentFormQuotaStore(_ inner: MemoryConsentFormQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormQuotaStore {
        return CachedConsentFormQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form quotas. Empty fields match all.
    final class ConsentFormQuotaQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormQuota]) -> [ConsentFormQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormQuotas(_ store: any ConsentFormQuotaStore, query: ConsentFormQuotaQuery) -> [ConsentFormQuota] {
        return query.apply(store.list())
    }
}

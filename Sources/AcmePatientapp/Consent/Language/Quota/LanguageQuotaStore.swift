import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language quotas by code.
    protocol LanguageQuotaStore {
        func find(_ code: String) -> LanguageQuota?
        func save(_ item: LanguageQuota)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageQuotaStore: LanguageQuotaStore {
        var items: [String: LanguageQuota]
        var order: [String]

        init(items: [String: LanguageQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageQuota) {
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

        func list() -> [LanguageQuota] {
            var out: [LanguageQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageQuotaStore() -> any LanguageQuotaStore {
        return MemoryLanguageQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageQuotaStore: LanguageQuotaStore {
        var inner: MemoryLanguageQuotaStore
        var cache: TTLCache<LanguageQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageQuotaStore, cache: TTLCache<LanguageQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageQuota? {
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

        func save(_ item: LanguageQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageQuota] {
            return inner.list()
        }
    }

    static func newCachedLanguageQuotaStore(_ inner: MemoryLanguageQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageQuotaStore {
        return CachedLanguageQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language quotas. Empty fields match all.
    final class LanguageQuotaQuery {
        var title: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LanguageQuota]) -> [LanguageQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageQuotas(_ store: any LanguageQuotaStore, query: LanguageQuotaQuery) -> [LanguageQuota] {
        return query.apply(store.list())
    }
}

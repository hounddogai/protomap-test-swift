import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual substitution quotas by code.
    protocol ManualSubstitutionQuotaStore {
        func find(_ code: String) -> ManualSubstitutionQuota?
        func save(_ item: ManualSubstitutionQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSubstitutionQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSubstitutionQuotaStore: ManualSubstitutionQuotaStore {
        var items: [String: ManualSubstitutionQuota]
        var order: [String]

        init(items: [String: ManualSubstitutionQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSubstitutionQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSubstitutionQuota) {
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

        func list() -> [ManualSubstitutionQuota] {
            var out: [ManualSubstitutionQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSubstitutionQuotaStore() -> any ManualSubstitutionQuotaStore {
        return MemoryManualSubstitutionQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSubstitutionQuotaStore: ManualSubstitutionQuotaStore {
        var inner: MemoryManualSubstitutionQuotaStore
        var cache: TTLCache<ManualSubstitutionQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSubstitutionQuotaStore, cache: TTLCache<ManualSubstitutionQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSubstitutionQuota? {
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

        func save(_ item: ManualSubstitutionQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSubstitutionQuota] {
            return inner.list()
        }
    }

    static func newCachedManualSubstitutionQuotaStore(_ inner: MemoryManualSubstitutionQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSubstitutionQuotaStore {
        return CachedManualSubstitutionQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual substitution quotas. Empty fields match all.
    final class ManualSubstitutionQuotaQuery {
        var title: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRefills: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSubstitutionQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSubstitutionQuota]) -> [ManualSubstitutionQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSubstitutionQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSubstitutionQuotas(_ store: any ManualSubstitutionQuotaStore, query: ManualSubstitutionQuotaQuery) -> [ManualSubstitutionQuota] {
        return query.apply(store.list())
    }
}

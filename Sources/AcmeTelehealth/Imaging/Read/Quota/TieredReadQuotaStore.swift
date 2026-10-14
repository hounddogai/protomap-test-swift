import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered read quotas by code.
    protocol TieredReadQuotaStore {
        func find(_ code: String) -> TieredReadQuota?
        func save(_ item: TieredReadQuota)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReadQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReadQuotaStore: TieredReadQuotaStore {
        var items: [String: TieredReadQuota]
        var order: [String]

        init(items: [String: TieredReadQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReadQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReadQuota) {
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

        func list() -> [TieredReadQuota] {
            var out: [TieredReadQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReadQuotaStore() -> any TieredReadQuotaStore {
        return MemoryTieredReadQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReadQuotaStore: TieredReadQuotaStore {
        var inner: MemoryTieredReadQuotaStore
        var cache: TTLCache<TieredReadQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReadQuotaStore, cache: TTLCache<TieredReadQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReadQuota? {
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

        func save(_ item: TieredReadQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReadQuota] {
            return inner.list()
        }
    }

    static func newCachedTieredReadQuotaStore(_ inner: MemoryTieredReadQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReadQuotaStore {
        return CachedTieredReadQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered read quotas. Empty fields match all.
    final class TieredReadQuotaQuery {
        var locale: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minScore: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReadQuota) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReadQuota]) -> [TieredReadQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReadQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReadQuotas(_ store: any TieredReadQuotaStore, query: TieredReadQuotaQuery) -> [TieredReadQuota] {
        return query.apply(store.list())
    }
}

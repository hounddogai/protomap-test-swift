import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered program quotas by code.
    protocol TieredProgramQuotaStore {
        func find(_ code: String) -> TieredProgramQuota?
        func save(_ item: TieredProgramQuota)
        func remove(_ code: String) -> Bool
        func list() -> [TieredProgramQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredProgramQuotaStore: TieredProgramQuotaStore {
        var items: [String: TieredProgramQuota]
        var order: [String]

        init(items: [String: TieredProgramQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredProgramQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredProgramQuota) {
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

        func list() -> [TieredProgramQuota] {
            var out: [TieredProgramQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredProgramQuotaStore() -> any TieredProgramQuotaStore {
        return MemoryTieredProgramQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredProgramQuotaStore: TieredProgramQuotaStore {
        var inner: MemoryTieredProgramQuotaStore
        var cache: TTLCache<TieredProgramQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredProgramQuotaStore, cache: TTLCache<TieredProgramQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredProgramQuota? {
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

        func save(_ item: TieredProgramQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredProgramQuota] {
            return inner.list()
        }
    }

    static func newCachedTieredProgramQuotaStore(_ inner: MemoryTieredProgramQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredProgramQuotaStore {
        return CachedTieredProgramQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered program quotas. Empty fields match all.
    final class TieredProgramQuotaQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredProgramQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredProgramQuota]) -> [TieredProgramQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredProgramQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredProgramQuotas(_ store: any TieredProgramQuotaStore, query: TieredProgramQuotaQuery) -> [TieredProgramQuota] {
        return query.apply(store.list())
    }
}

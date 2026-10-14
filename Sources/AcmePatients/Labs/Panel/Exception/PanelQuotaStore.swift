import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel quotas by code.
    protocol PanelQuotaStore {
        func find(_ code: String) -> PanelQuota?
        func save(_ item: PanelQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PanelQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelQuotaStore: PanelQuotaStore {
        var items: [String: PanelQuota]
        var order: [String]

        init(items: [String: PanelQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelQuota) {
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

        func list() -> [PanelQuota] {
            var out: [PanelQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelQuotaStore() -> any PanelQuotaStore {
        return MemoryPanelQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelQuotaStore: PanelQuotaStore {
        var inner: MemoryPanelQuotaStore
        var cache: TTLCache<PanelQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelQuotaStore, cache: TTLCache<PanelQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelQuota? {
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

        func save(_ item: PanelQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelQuota] {
            return inner.list()
        }
    }

    static func newCachedPanelQuotaStore(_ inner: MemoryPanelQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelQuotaStore {
        return CachedPanelQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel quotas. Empty fields match all.
    final class PanelQuotaQuery {
        var category: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelQuota]) -> [PanelQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelQuotas(_ store: any PanelQuotaStore, query: PanelQuotaQuery) -> [PanelQuota] {
        return query.apply(store.list())
    }
}

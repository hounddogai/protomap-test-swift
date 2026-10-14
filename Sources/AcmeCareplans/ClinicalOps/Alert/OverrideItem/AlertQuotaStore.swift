import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert quotas by code.
    protocol AlertQuotaStore {
        func find(_ code: String) -> AlertQuota?
        func save(_ item: AlertQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AlertQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertQuotaStore: AlertQuotaStore {
        var items: [String: AlertQuota]
        var order: [String]

        init(items: [String: AlertQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertQuota) {
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

        func list() -> [AlertQuota] {
            var out: [AlertQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertQuotaStore() -> any AlertQuotaStore {
        return MemoryAlertQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertQuotaStore: AlertQuotaStore {
        var inner: MemoryAlertQuotaStore
        var cache: TTLCache<AlertQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertQuotaStore, cache: TTLCache<AlertQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertQuota? {
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

        func save(_ item: AlertQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertQuota] {
            return inner.list()
        }
    }

    static func newCachedAlertQuotaStore(_ inner: MemoryAlertQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertQuotaStore {
        return CachedAlertQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert quotas. Empty fields match all.
    final class AlertQuotaQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertQuota]) -> [AlertQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertQuotas(_ store: any AlertQuotaStore, query: AlertQuotaQuery) -> [AlertQuota] {
        return query.apply(store.list())
    }
}

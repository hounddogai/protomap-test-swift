import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy plans by code.
    protocol ProxyPlanStore {
        func find(_ code: String) -> ProxyPlan?
        func save(_ item: ProxyPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyPlanStore: ProxyPlanStore {
        var items: [String: ProxyPlan]
        var order: [String]

        init(items: [String: ProxyPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyPlan) {
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

        func list() -> [ProxyPlan] {
            var out: [ProxyPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyPlanStore() -> any ProxyPlanStore {
        return MemoryProxyPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyPlanStore: ProxyPlanStore {
        var inner: MemoryProxyPlanStore
        var cache: TTLCache<ProxyPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyPlanStore, cache: TTLCache<ProxyPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyPlan? {
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

        func save(_ item: ProxyPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyPlan] {
            return inner.list()
        }
    }

    static func newCachedProxyPlanStore(_ inner: MemoryProxyPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyPlanStore {
        return CachedProxyPlanStore(inner: inner, cache: newTTLCache(64, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects proxy plans. Empty fields match all.
    final class ProxyPlanQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyPlan]) -> [ProxyPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyPlans(_ store: any ProxyPlanStore, query: ProxyPlanQuery) -> [ProxyPlan] {
        return query.apply(store.list())
    }
}

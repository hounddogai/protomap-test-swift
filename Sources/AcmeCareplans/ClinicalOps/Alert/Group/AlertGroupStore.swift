import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert groups by code.
    protocol AlertGroupStore {
        func find(_ code: String) -> AlertGroup?
        func save(_ item: AlertGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AlertGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertGroupStore: AlertGroupStore {
        var items: [String: AlertGroup]
        var order: [String]

        init(items: [String: AlertGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertGroup) {
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

        func list() -> [AlertGroup] {
            var out: [AlertGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertGroupStore() -> any AlertGroupStore {
        return MemoryAlertGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertGroupStore: AlertGroupStore {
        var inner: MemoryAlertGroupStore
        var cache: TTLCache<AlertGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertGroupStore, cache: TTLCache<AlertGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertGroup? {
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

        func save(_ item: AlertGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertGroup] {
            return inner.list()
        }
    }

    static func newCachedAlertGroupStore(_ inner: MemoryAlertGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertGroupStore {
        return CachedAlertGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert groups. Empty fields match all.
    final class AlertGroupQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertGroup) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertGroup]) -> [AlertGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertGroups(_ store: any AlertGroupStore, query: AlertGroupQuery) -> [AlertGroup] {
        return query.apply(store.list())
    }
}

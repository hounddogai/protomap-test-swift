import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert templates by code.
    protocol AlertTemplateStore {
        func find(_ code: String) -> AlertTemplate?
        func save(_ item: AlertTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AlertTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertTemplateStore: AlertTemplateStore {
        var items: [String: AlertTemplate]
        var order: [String]

        init(items: [String: AlertTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertTemplate) {
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

        func list() -> [AlertTemplate] {
            var out: [AlertTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertTemplateStore() -> any AlertTemplateStore {
        return MemoryAlertTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertTemplateStore: AlertTemplateStore {
        var inner: MemoryAlertTemplateStore
        var cache: TTLCache<AlertTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertTemplateStore, cache: TTLCache<AlertTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertTemplate? {
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

        func save(_ item: AlertTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertTemplate] {
            return inner.list()
        }
    }

    static func newCachedAlertTemplateStore(_ inner: MemoryAlertTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertTemplateStore {
        return CachedAlertTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert templates. Empty fields match all.
    final class AlertTemplateQuery {
        var locale: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCost: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertTemplate) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertTemplate]) -> [AlertTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertTemplates(_ store: any AlertTemplateStore, query: AlertTemplateQuery) -> [AlertTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan templates by code.
    protocol DischargePlanTemplateStore {
        func find(_ code: String) -> DischargePlanTemplate?
        func save(_ item: DischargePlanTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanTemplateStore: DischargePlanTemplateStore {
        var items: [String: DischargePlanTemplate]
        var order: [String]

        init(items: [String: DischargePlanTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanTemplate) {
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

        func list() -> [DischargePlanTemplate] {
            var out: [DischargePlanTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanTemplateStore() -> any DischargePlanTemplateStore {
        return MemoryDischargePlanTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanTemplateStore: DischargePlanTemplateStore {
        var inner: MemoryDischargePlanTemplateStore
        var cache: TTLCache<DischargePlanTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanTemplateStore, cache: TTLCache<DischargePlanTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanTemplate? {
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

        func save(_ item: DischargePlanTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanTemplate] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanTemplateStore(_ inner: MemoryDischargePlanTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanTemplateStore {
        return CachedDischargePlanTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan templates. Empty fields match all.
    final class DischargePlanTemplateQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanTemplate]) -> [DischargePlanTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanTemplates(_ store: any DischargePlanTemplateStore, query: DischargePlanTemplateQuery) -> [DischargePlanTemplate] {
        return query.apply(store.list())
    }
}

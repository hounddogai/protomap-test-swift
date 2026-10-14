import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan templates by code.
    protocol AcuityPlanTemplateStore {
        func find(_ code: String) -> AcuityPlanTemplate?
        func save(_ item: AcuityPlanTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanTemplateStore: AcuityPlanTemplateStore {
        var items: [String: AcuityPlanTemplate]
        var order: [String]

        init(items: [String: AcuityPlanTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanTemplate) {
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

        func list() -> [AcuityPlanTemplate] {
            var out: [AcuityPlanTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanTemplateStore() -> any AcuityPlanTemplateStore {
        return MemoryAcuityPlanTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanTemplateStore: AcuityPlanTemplateStore {
        var inner: MemoryAcuityPlanTemplateStore
        var cache: TTLCache<AcuityPlanTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanTemplateStore, cache: TTLCache<AcuityPlanTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanTemplate? {
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

        func save(_ item: AcuityPlanTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanTemplate] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanTemplateStore(_ inner: MemoryAcuityPlanTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanTemplateStore {
        return CachedAcuityPlanTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan templates. Empty fields match all.
    final class AcuityPlanTemplateQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanTemplate]) -> [AcuityPlanTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanTemplates(_ store: any AcuityPlanTemplateStore, query: AcuityPlanTemplateQuery) -> [AcuityPlanTemplate] {
        return query.apply(store.list())
    }
}

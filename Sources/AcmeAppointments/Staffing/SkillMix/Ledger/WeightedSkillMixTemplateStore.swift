import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted skill mix templates by code.
    protocol WeightedSkillMixTemplateStore {
        func find(_ code: String) -> WeightedSkillMixTemplate?
        func save(_ item: WeightedSkillMixTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSkillMixTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSkillMixTemplateStore: WeightedSkillMixTemplateStore {
        var items: [String: WeightedSkillMixTemplate]
        var order: [String]

        init(items: [String: WeightedSkillMixTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSkillMixTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSkillMixTemplate) {
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

        func list() -> [WeightedSkillMixTemplate] {
            var out: [WeightedSkillMixTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSkillMixTemplateStore() -> any WeightedSkillMixTemplateStore {
        return MemoryWeightedSkillMixTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSkillMixTemplateStore: WeightedSkillMixTemplateStore {
        var inner: MemoryWeightedSkillMixTemplateStore
        var cache: TTLCache<WeightedSkillMixTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSkillMixTemplateStore, cache: TTLCache<WeightedSkillMixTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSkillMixTemplate? {
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

        func save(_ item: WeightedSkillMixTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSkillMixTemplate] {
            return inner.list()
        }
    }

    static func newCachedWeightedSkillMixTemplateStore(_ inner: MemoryWeightedSkillMixTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSkillMixTemplateStore {
        return CachedWeightedSkillMixTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted skill mix templates. Empty fields match all.
    final class WeightedSkillMixTemplateQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSkillMixTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedSkillMixTemplate]) -> [WeightedSkillMixTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSkillMixTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSkillMixTemplates(_ store: any WeightedSkillMixTemplateStore, query: WeightedSkillMixTemplateQuery) -> [WeightedSkillMixTemplate] {
        return query.apply(store.list())
    }
}

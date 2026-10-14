import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict skill mix templates by code.
    protocol StrictSkillMixTemplateStore {
        func find(_ code: String) -> StrictSkillMixTemplate?
        func save(_ item: StrictSkillMixTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSkillMixTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSkillMixTemplateStore: StrictSkillMixTemplateStore {
        var items: [String: StrictSkillMixTemplate]
        var order: [String]

        init(items: [String: StrictSkillMixTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSkillMixTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSkillMixTemplate) {
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

        func list() -> [StrictSkillMixTemplate] {
            var out: [StrictSkillMixTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSkillMixTemplateStore() -> any StrictSkillMixTemplateStore {
        return MemoryStrictSkillMixTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSkillMixTemplateStore: StrictSkillMixTemplateStore {
        var inner: MemoryStrictSkillMixTemplateStore
        var cache: TTLCache<StrictSkillMixTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSkillMixTemplateStore, cache: TTLCache<StrictSkillMixTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSkillMixTemplate? {
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

        func save(_ item: StrictSkillMixTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSkillMixTemplate] {
            return inner.list()
        }
    }

    static func newCachedStrictSkillMixTemplateStore(_ inner: MemoryStrictSkillMixTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSkillMixTemplateStore {
        return CachedStrictSkillMixTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict skill mix templates. Empty fields match all.
    final class StrictSkillMixTemplateQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSkillMixTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSkillMixTemplate]) -> [StrictSkillMixTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSkillMixTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSkillMixTemplates(_ store: any StrictSkillMixTemplateStore, query: StrictSkillMixTemplateQuery) -> [StrictSkillMixTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling goal templates by code.
    protocol RollingGoalTemplateStore {
        func find(_ code: String) -> RollingGoalTemplate?
        func save(_ item: RollingGoalTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [RollingGoalTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingGoalTemplateStore: RollingGoalTemplateStore {
        var items: [String: RollingGoalTemplate]
        var order: [String]

        init(items: [String: RollingGoalTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingGoalTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingGoalTemplate) {
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

        func list() -> [RollingGoalTemplate] {
            var out: [RollingGoalTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingGoalTemplateStore() -> any RollingGoalTemplateStore {
        return MemoryRollingGoalTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingGoalTemplateStore: RollingGoalTemplateStore {
        var inner: MemoryRollingGoalTemplateStore
        var cache: TTLCache<RollingGoalTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingGoalTemplateStore, cache: TTLCache<RollingGoalTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingGoalTemplate? {
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

        func save(_ item: RollingGoalTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingGoalTemplate] {
            return inner.list()
        }
    }

    static func newCachedRollingGoalTemplateStore(_ inner: MemoryRollingGoalTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingGoalTemplateStore {
        return CachedRollingGoalTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling goal templates. Empty fields match all.
    final class RollingGoalTemplateQuery {
        var unit: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingGoalTemplate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RollingGoalTemplate]) -> [RollingGoalTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingGoalTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingGoalTemplates(_ store: any RollingGoalTemplateStore, query: RollingGoalTemplateQuery) -> [RollingGoalTemplate] {
        return query.apply(store.list())
    }
}

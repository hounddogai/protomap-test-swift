import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy recall templates by code.
    protocol LegacyRecallTemplateStore {
        func find(_ code: String) -> LegacyRecallTemplate?
        func save(_ item: LegacyRecallTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyRecallTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyRecallTemplateStore: LegacyRecallTemplateStore {
        var items: [String: LegacyRecallTemplate]
        var order: [String]

        init(items: [String: LegacyRecallTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyRecallTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyRecallTemplate) {
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

        func list() -> [LegacyRecallTemplate] {
            var out: [LegacyRecallTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyRecallTemplateStore() -> any LegacyRecallTemplateStore {
        return MemoryLegacyRecallTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyRecallTemplateStore: LegacyRecallTemplateStore {
        var inner: MemoryLegacyRecallTemplateStore
        var cache: TTLCache<LegacyRecallTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyRecallTemplateStore, cache: TTLCache<LegacyRecallTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyRecallTemplate? {
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

        func save(_ item: LegacyRecallTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyRecallTemplate] {
            return inner.list()
        }
    }

    static func newCachedLegacyRecallTemplateStore(_ inner: MemoryLegacyRecallTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyRecallTemplateStore {
        return CachedLegacyRecallTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy recall templates. Empty fields match all.
    final class LegacyRecallTemplateQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyRecallTemplate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [LegacyRecallTemplate]) -> [LegacyRecallTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyRecallTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyRecallTemplates(_ store: any LegacyRecallTemplateStore, query: LegacyRecallTemplateQuery) -> [LegacyRecallTemplate] {
        return query.apply(store.list())
    }
}

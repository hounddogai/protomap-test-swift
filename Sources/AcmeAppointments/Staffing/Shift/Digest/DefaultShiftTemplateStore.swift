import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default shift templates by code.
    protocol DefaultShiftTemplateStore {
        func find(_ code: String) -> DefaultShiftTemplate?
        func save(_ item: DefaultShiftTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultShiftTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultShiftTemplateStore: DefaultShiftTemplateStore {
        var items: [String: DefaultShiftTemplate]
        var order: [String]

        init(items: [String: DefaultShiftTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultShiftTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultShiftTemplate) {
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

        func list() -> [DefaultShiftTemplate] {
            var out: [DefaultShiftTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultShiftTemplateStore() -> any DefaultShiftTemplateStore {
        return MemoryDefaultShiftTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultShiftTemplateStore: DefaultShiftTemplateStore {
        var inner: MemoryDefaultShiftTemplateStore
        var cache: TTLCache<DefaultShiftTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultShiftTemplateStore, cache: TTLCache<DefaultShiftTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultShiftTemplate? {
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

        func save(_ item: DefaultShiftTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultShiftTemplate] {
            return inner.list()
        }
    }

    static func newCachedDefaultShiftTemplateStore(_ inner: MemoryDefaultShiftTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultShiftTemplateStore {
        return CachedDefaultShiftTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default shift templates. Empty fields match all.
    final class DefaultShiftTemplateQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultShiftTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultShiftTemplate]) -> [DefaultShiftTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultShiftTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultShiftTemplates(_ store: any DefaultShiftTemplateStore, query: DefaultShiftTemplateQuery) -> [DefaultShiftTemplate] {
        return query.apply(store.list())
    }
}

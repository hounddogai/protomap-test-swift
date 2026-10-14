import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional courier templates by code.
    protocol RegionalCourierTemplateStore {
        func find(_ code: String) -> RegionalCourierTemplate?
        func save(_ item: RegionalCourierTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCourierTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCourierTemplateStore: RegionalCourierTemplateStore {
        var items: [String: RegionalCourierTemplate]
        var order: [String]

        init(items: [String: RegionalCourierTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCourierTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCourierTemplate) {
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

        func list() -> [RegionalCourierTemplate] {
            var out: [RegionalCourierTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCourierTemplateStore() -> any RegionalCourierTemplateStore {
        return MemoryRegionalCourierTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCourierTemplateStore: RegionalCourierTemplateStore {
        var inner: MemoryRegionalCourierTemplateStore
        var cache: TTLCache<RegionalCourierTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCourierTemplateStore, cache: TTLCache<RegionalCourierTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCourierTemplate? {
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

        func save(_ item: RegionalCourierTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCourierTemplate] {
            return inner.list()
        }
    }

    static func newCachedRegionalCourierTemplateStore(_ inner: MemoryRegionalCourierTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCourierTemplateStore {
        return CachedRegionalCourierTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional courier templates. Empty fields match all.
    final class RegionalCourierTemplateQuery {
        var facility: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRatio: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCourierTemplate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [RegionalCourierTemplate]) -> [RegionalCourierTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCourierTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCourierTemplates(_ store: any RegionalCourierTemplateStore, query: RegionalCourierTemplateQuery) -> [RegionalCourierTemplate] {
        return query.apply(store.list())
    }
}

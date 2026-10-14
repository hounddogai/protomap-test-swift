import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy bed board templates by code.
    protocol LegacyBedBoardTemplateStore {
        func find(_ code: String) -> LegacyBedBoardTemplate?
        func save(_ item: LegacyBedBoardTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyBedBoardTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyBedBoardTemplateStore: LegacyBedBoardTemplateStore {
        var items: [String: LegacyBedBoardTemplate]
        var order: [String]

        init(items: [String: LegacyBedBoardTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyBedBoardTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyBedBoardTemplate) {
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

        func list() -> [LegacyBedBoardTemplate] {
            var out: [LegacyBedBoardTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyBedBoardTemplateStore() -> any LegacyBedBoardTemplateStore {
        return MemoryLegacyBedBoardTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyBedBoardTemplateStore: LegacyBedBoardTemplateStore {
        var inner: MemoryLegacyBedBoardTemplateStore
        var cache: TTLCache<LegacyBedBoardTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyBedBoardTemplateStore, cache: TTLCache<LegacyBedBoardTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyBedBoardTemplate? {
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

        func save(_ item: LegacyBedBoardTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyBedBoardTemplate] {
            return inner.list()
        }
    }

    static func newCachedLegacyBedBoardTemplateStore(_ inner: MemoryLegacyBedBoardTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyBedBoardTemplateStore {
        return CachedLegacyBedBoardTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy bed board templates. Empty fields match all.
    final class LegacyBedBoardTemplateQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyBedBoardTemplate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyBedBoardTemplate]) -> [LegacyBedBoardTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyBedBoardTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyBedBoardTemplates(_ store: any LegacyBedBoardTemplateStore, query: LegacyBedBoardTemplateQuery) -> [LegacyBedBoardTemplate] {
        return query.apply(store.list())
    }
}

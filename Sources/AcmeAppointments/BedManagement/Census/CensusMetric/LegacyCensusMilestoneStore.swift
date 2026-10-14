import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy census milestones by code.
    protocol LegacyCensusMilestoneStore {
        func find(_ code: String) -> LegacyCensusMilestone?
        func save(_ item: LegacyCensusMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCensusMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCensusMilestoneStore: LegacyCensusMilestoneStore {
        var items: [String: LegacyCensusMilestone]
        var order: [String]

        init(items: [String: LegacyCensusMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCensusMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCensusMilestone) {
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

        func list() -> [LegacyCensusMilestone] {
            var out: [LegacyCensusMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCensusMilestoneStore() -> any LegacyCensusMilestoneStore {
        return MemoryLegacyCensusMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCensusMilestoneStore: LegacyCensusMilestoneStore {
        var inner: MemoryLegacyCensusMilestoneStore
        var cache: TTLCache<LegacyCensusMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCensusMilestoneStore, cache: TTLCache<LegacyCensusMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCensusMilestone? {
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

        func save(_ item: LegacyCensusMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCensusMilestone] {
            return inner.list()
        }
    }

    static func newCachedLegacyCensusMilestoneStore(_ inner: MemoryLegacyCensusMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCensusMilestoneStore {
        return CachedLegacyCensusMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy census milestones. Empty fields match all.
    final class LegacyCensusMilestoneQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCensusMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LegacyCensusMilestone]) -> [LegacyCensusMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCensusMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCensusMilestones(_ store: any LegacyCensusMilestoneStore, query: LegacyCensusMilestoneQuery) -> [LegacyCensusMilestone] {
        return query.apply(store.list())
    }
}

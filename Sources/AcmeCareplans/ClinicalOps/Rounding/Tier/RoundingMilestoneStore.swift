import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding milestones by code.
    protocol RoundingMilestoneStore {
        func find(_ code: String) -> RoundingMilestone?
        func save(_ item: RoundingMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingMilestoneStore: RoundingMilestoneStore {
        var items: [String: RoundingMilestone]
        var order: [String]

        init(items: [String: RoundingMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingMilestone) {
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

        func list() -> [RoundingMilestone] {
            var out: [RoundingMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingMilestoneStore() -> any RoundingMilestoneStore {
        return MemoryRoundingMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingMilestoneStore: RoundingMilestoneStore {
        var inner: MemoryRoundingMilestoneStore
        var cache: TTLCache<RoundingMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingMilestoneStore, cache: TTLCache<RoundingMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingMilestone? {
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

        func save(_ item: RoundingMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingMilestone] {
            return inner.list()
        }
    }

    static func newCachedRoundingMilestoneStore(_ inner: MemoryRoundingMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingMilestoneStore {
        return CachedRoundingMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding milestones. Empty fields match all.
    final class RoundingMilestoneQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingMilestone]) -> [RoundingMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingMilestones(_ store: any RoundingMilestoneStore, query: RoundingMilestoneQuery) -> [RoundingMilestone] {
        return query.apply(store.list())
    }
}

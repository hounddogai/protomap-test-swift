import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global denial milestones by code.
    protocol GlobalDenialMilestoneStore {
        func find(_ code: String) -> GlobalDenialMilestone?
        func save(_ item: GlobalDenialMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDenialMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDenialMilestoneStore: GlobalDenialMilestoneStore {
        var items: [String: GlobalDenialMilestone]
        var order: [String]

        init(items: [String: GlobalDenialMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDenialMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDenialMilestone) {
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

        func list() -> [GlobalDenialMilestone] {
            var out: [GlobalDenialMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDenialMilestoneStore() -> any GlobalDenialMilestoneStore {
        return MemoryGlobalDenialMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDenialMilestoneStore: GlobalDenialMilestoneStore {
        var inner: MemoryGlobalDenialMilestoneStore
        var cache: TTLCache<GlobalDenialMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDenialMilestoneStore, cache: TTLCache<GlobalDenialMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDenialMilestone? {
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

        func save(_ item: GlobalDenialMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDenialMilestone] {
            return inner.list()
        }
    }

    static func newCachedGlobalDenialMilestoneStore(_ inner: MemoryGlobalDenialMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDenialMilestoneStore {
        return CachedGlobalDenialMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global denial milestones. Empty fields match all.
    final class GlobalDenialMilestoneQuery {
        var locale: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDenialMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [GlobalDenialMilestone]) -> [GlobalDenialMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDenialMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDenialMilestones(_ store: any GlobalDenialMilestoneStore, query: GlobalDenialMilestoneQuery) -> [GlobalDenialMilestone] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient specimen milestones by code.
    protocol LenientSpecimenMilestoneStore {
        func find(_ code: String) -> LenientSpecimenMilestone?
        func save(_ item: LenientSpecimenMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSpecimenMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSpecimenMilestoneStore: LenientSpecimenMilestoneStore {
        var items: [String: LenientSpecimenMilestone]
        var order: [String]

        init(items: [String: LenientSpecimenMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSpecimenMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSpecimenMilestone) {
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

        func list() -> [LenientSpecimenMilestone] {
            var out: [LenientSpecimenMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSpecimenMilestoneStore() -> any LenientSpecimenMilestoneStore {
        return MemoryLenientSpecimenMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSpecimenMilestoneStore: LenientSpecimenMilestoneStore {
        var inner: MemoryLenientSpecimenMilestoneStore
        var cache: TTLCache<LenientSpecimenMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSpecimenMilestoneStore, cache: TTLCache<LenientSpecimenMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSpecimenMilestone? {
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

        func save(_ item: LenientSpecimenMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSpecimenMilestone] {
            return inner.list()
        }
    }

    static func newCachedLenientSpecimenMilestoneStore(_ inner: MemoryLenientSpecimenMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSpecimenMilestoneStore {
        return CachedLenientSpecimenMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient specimen milestones. Empty fields match all.
    final class LenientSpecimenMilestoneQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSpecimenMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSpecimenMilestone]) -> [LenientSpecimenMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSpecimenMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSpecimenMilestones(_ store: any LenientSpecimenMilestoneStore, query: LenientSpecimenMilestoneQuery) -> [LenientSpecimenMilestone] {
        return query.apply(store.list())
    }
}

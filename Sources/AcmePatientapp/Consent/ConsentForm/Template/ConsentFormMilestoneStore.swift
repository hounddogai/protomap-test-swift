import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form milestones by code.
    protocol ConsentFormMilestoneStore {
        func find(_ code: String) -> ConsentFormMilestone?
        func save(_ item: ConsentFormMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormMilestoneStore: ConsentFormMilestoneStore {
        var items: [String: ConsentFormMilestone]
        var order: [String]

        init(items: [String: ConsentFormMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormMilestone) {
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

        func list() -> [ConsentFormMilestone] {
            var out: [ConsentFormMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormMilestoneStore() -> any ConsentFormMilestoneStore {
        return MemoryConsentFormMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormMilestoneStore: ConsentFormMilestoneStore {
        var inner: MemoryConsentFormMilestoneStore
        var cache: TTLCache<ConsentFormMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormMilestoneStore, cache: TTLCache<ConsentFormMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormMilestone? {
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

        func save(_ item: ConsentFormMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormMilestone] {
            return inner.list()
        }
    }

    static func newCachedConsentFormMilestoneStore(_ inner: MemoryConsentFormMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormMilestoneStore {
        return CachedConsentFormMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form milestones. Empty fields match all.
    final class ConsentFormMilestoneQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ConsentFormMilestone]) -> [ConsentFormMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormMilestones(_ store: any ConsentFormMilestoneStore, query: ConsentFormMilestoneQuery) -> [ConsentFormMilestone] {
        return query.apply(store.list())
    }
}

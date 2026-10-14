import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled study rules by code.
    protocol ScheduledStudyRuleStore {
        func find(_ code: String) -> ScheduledStudyRule?
        func save(_ item: ScheduledStudyRule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledStudyRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledStudyRuleStore: ScheduledStudyRuleStore {
        var items: [String: ScheduledStudyRule]
        var order: [String]

        init(items: [String: ScheduledStudyRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledStudyRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledStudyRule) {
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

        func list() -> [ScheduledStudyRule] {
            var out: [ScheduledStudyRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledStudyRuleStore() -> any ScheduledStudyRuleStore {
        return MemoryScheduledStudyRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledStudyRuleStore: ScheduledStudyRuleStore {
        var inner: MemoryScheduledStudyRuleStore
        var cache: TTLCache<ScheduledStudyRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledStudyRuleStore, cache: TTLCache<ScheduledStudyRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledStudyRule? {
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

        func save(_ item: ScheduledStudyRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledStudyRule] {
            return inner.list()
        }
    }

    static func newCachedScheduledStudyRuleStore(_ inner: MemoryScheduledStudyRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledStudyRuleStore {
        return CachedScheduledStudyRuleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled study rules. Empty fields match all.
    final class ScheduledStudyRuleQuery {
        var facility: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledStudyRule) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledStudyRule]) -> [ScheduledStudyRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledStudyRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledStudyRules(_ store: any ScheduledStudyRuleStore, query: ScheduledStudyRuleQuery) -> [ScheduledStudyRule] {
        return query.apply(store.list())
    }
}

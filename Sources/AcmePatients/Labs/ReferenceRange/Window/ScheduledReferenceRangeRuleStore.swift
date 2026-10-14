import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled reference range rules by code.
    protocol ScheduledReferenceRangeRuleStore {
        func find(_ code: String) -> ScheduledReferenceRangeRule?
        func save(_ item: ScheduledReferenceRangeRule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReferenceRangeRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReferenceRangeRuleStore: ScheduledReferenceRangeRuleStore {
        var items: [String: ScheduledReferenceRangeRule]
        var order: [String]

        init(items: [String: ScheduledReferenceRangeRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReferenceRangeRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReferenceRangeRule) {
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

        func list() -> [ScheduledReferenceRangeRule] {
            var out: [ScheduledReferenceRangeRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReferenceRangeRuleStore() -> any ScheduledReferenceRangeRuleStore {
        return MemoryScheduledReferenceRangeRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReferenceRangeRuleStore: ScheduledReferenceRangeRuleStore {
        var inner: MemoryScheduledReferenceRangeRuleStore
        var cache: TTLCache<ScheduledReferenceRangeRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReferenceRangeRuleStore, cache: TTLCache<ScheduledReferenceRangeRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReferenceRangeRule? {
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

        func save(_ item: ScheduledReferenceRangeRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReferenceRangeRule] {
            return inner.list()
        }
    }

    static func newCachedScheduledReferenceRangeRuleStore(_ inner: MemoryScheduledReferenceRangeRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReferenceRangeRuleStore {
        return CachedScheduledReferenceRangeRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled reference range rules. Empty fields match all.
    final class ScheduledReferenceRangeRuleQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReferenceRangeRule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReferenceRangeRule]) -> [ScheduledReferenceRangeRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReferenceRangeRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReferenceRangeRules(_ store: any ScheduledReferenceRangeRuleStore, query: ScheduledReferenceRangeRuleQuery) -> [ScheduledReferenceRangeRule] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled census rules by code.
    protocol ScheduledCensusRuleStore {
        func find(_ code: String) -> ScheduledCensusRule?
        func save(_ item: ScheduledCensusRule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCensusRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCensusRuleStore: ScheduledCensusRuleStore {
        var items: [String: ScheduledCensusRule]
        var order: [String]

        init(items: [String: ScheduledCensusRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCensusRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCensusRule) {
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

        func list() -> [ScheduledCensusRule] {
            var out: [ScheduledCensusRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCensusRuleStore() -> any ScheduledCensusRuleStore {
        return MemoryScheduledCensusRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCensusRuleStore: ScheduledCensusRuleStore {
        var inner: MemoryScheduledCensusRuleStore
        var cache: TTLCache<ScheduledCensusRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCensusRuleStore, cache: TTLCache<ScheduledCensusRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCensusRule? {
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

        func save(_ item: ScheduledCensusRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCensusRule] {
            return inner.list()
        }
    }

    static func newCachedScheduledCensusRuleStore(_ inner: MemoryScheduledCensusRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCensusRuleStore {
        return CachedScheduledCensusRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled census rules. Empty fields match all.
    final class ScheduledCensusRuleQuery {
        var region: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCopay: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCensusRule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCensusRule]) -> [ScheduledCensusRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCensusRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCensusRules(_ store: any ScheduledCensusRuleStore, query: ScheduledCensusRuleQuery) -> [ScheduledCensusRule] {
        return query.apply(store.list())
    }
}

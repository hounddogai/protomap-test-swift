import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan rules by code.
    protocol DischargePlanRuleStore {
        func find(_ code: String) -> DischargePlanRule?
        func save(_ item: DischargePlanRule)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanRuleStore: DischargePlanRuleStore {
        var items: [String: DischargePlanRule]
        var order: [String]

        init(items: [String: DischargePlanRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanRule) {
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

        func list() -> [DischargePlanRule] {
            var out: [DischargePlanRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanRuleStore() -> any DischargePlanRuleStore {
        return MemoryDischargePlanRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanRuleStore: DischargePlanRuleStore {
        var inner: MemoryDischargePlanRuleStore
        var cache: TTLCache<DischargePlanRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanRuleStore, cache: TTLCache<DischargePlanRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanRule? {
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

        func save(_ item: DischargePlanRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanRule] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanRuleStore(_ inner: MemoryDischargePlanRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanRuleStore {
        return CachedDischargePlanRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan rules. Empty fields match all.
    final class DischargePlanRuleQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanRule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanRule]) -> [DischargePlanRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanRules(_ store: any DischargePlanRuleStore, query: DischargePlanRuleQuery) -> [DischargePlanRule] {
        return query.apply(store.list())
    }
}

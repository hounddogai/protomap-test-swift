import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual priority rules by code.
    protocol ManualPriorityRuleStore {
        func find(_ code: String) -> ManualPriorityRule?
        func save(_ item: ManualPriorityRule)
        func remove(_ code: String) -> Bool
        func list() -> [ManualPriorityRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualPriorityRuleStore: ManualPriorityRuleStore {
        var items: [String: ManualPriorityRule]
        var order: [String]

        init(items: [String: ManualPriorityRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualPriorityRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualPriorityRule) {
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

        func list() -> [ManualPriorityRule] {
            var out: [ManualPriorityRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualPriorityRuleStore() -> any ManualPriorityRuleStore {
        return MemoryManualPriorityRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualPriorityRuleStore: ManualPriorityRuleStore {
        var inner: MemoryManualPriorityRuleStore
        var cache: TTLCache<ManualPriorityRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualPriorityRuleStore, cache: TTLCache<ManualPriorityRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualPriorityRule? {
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

        func save(_ item: ManualPriorityRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualPriorityRule] {
            return inner.list()
        }
    }

    static func newCachedManualPriorityRuleStore(_ inner: MemoryManualPriorityRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualPriorityRuleStore {
        return CachedManualPriorityRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual priority rules. Empty fields match all.
    final class ManualPriorityRuleQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualPriorityRule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualPriorityRule]) -> [ManualPriorityRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualPriorityRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualPriorityRules(_ store: any ManualPriorityRuleStore, query: ManualPriorityRuleQuery) -> [ManualPriorityRule] {
        return query.apply(store.list())
    }
}

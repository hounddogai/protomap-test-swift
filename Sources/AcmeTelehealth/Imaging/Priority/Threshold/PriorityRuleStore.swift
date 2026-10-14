import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority rules by code.
    protocol PriorityRuleStore {
        func find(_ code: String) -> PriorityRule?
        func save(_ item: PriorityRule)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityRuleStore: PriorityRuleStore {
        var items: [String: PriorityRule]
        var order: [String]

        init(items: [String: PriorityRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityRule) {
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

        func list() -> [PriorityRule] {
            var out: [PriorityRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityRuleStore() -> any PriorityRuleStore {
        return MemoryPriorityRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityRuleStore: PriorityRuleStore {
        var inner: MemoryPriorityRuleStore
        var cache: TTLCache<PriorityRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityRuleStore, cache: TTLCache<PriorityRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityRule? {
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

        func save(_ item: PriorityRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityRule] {
            return inner.list()
        }
    }

    static func newCachedPriorityRuleStore(_ inner: MemoryPriorityRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityRuleStore {
        return CachedPriorityRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority rules. Empty fields match all.
    final class PriorityRuleQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityRule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityRule]) -> [PriorityRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityRules(_ store: any PriorityRuleStore, query: PriorityRuleQuery) -> [PriorityRule] {
        return query.apply(store.list())
    }
}

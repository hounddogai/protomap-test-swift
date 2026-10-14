import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure rules by code.
    protocol ClosureRuleStore {
        func find(_ code: String) -> ClosureRule?
        func save(_ item: ClosureRule)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureRuleStore: ClosureRuleStore {
        var items: [String: ClosureRule]
        var order: [String]

        init(items: [String: ClosureRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureRule) {
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

        func list() -> [ClosureRule] {
            var out: [ClosureRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureRuleStore() -> any ClosureRuleStore {
        return MemoryClosureRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureRuleStore: ClosureRuleStore {
        var inner: MemoryClosureRuleStore
        var cache: TTLCache<ClosureRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureRuleStore, cache: TTLCache<ClosureRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureRule? {
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

        func save(_ item: ClosureRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureRule] {
            return inner.list()
        }
    }

    static func newCachedClosureRuleStore(_ inner: MemoryClosureRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureRuleStore {
        return CachedClosureRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure rules. Empty fields match all.
    final class ClosureRuleQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureRule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClosureRule]) -> [ClosureRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureRules(_ store: any ClosureRuleStore, query: ClosureRuleQuery) -> [ClosureRule] {
        return query.apply(store.list())
    }
}

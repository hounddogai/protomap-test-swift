import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction rules by code.
    protocol InteractionRuleStore {
        func find(_ code: String) -> InteractionRule?
        func save(_ item: InteractionRule)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionRuleStore: InteractionRuleStore {
        var items: [String: InteractionRule]
        var order: [String]

        init(items: [String: InteractionRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionRule) {
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

        func list() -> [InteractionRule] {
            var out: [InteractionRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionRuleStore() -> any InteractionRuleStore {
        return MemoryInteractionRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionRuleStore: InteractionRuleStore {
        var inner: MemoryInteractionRuleStore
        var cache: TTLCache<InteractionRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionRuleStore, cache: TTLCache<InteractionRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionRule? {
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

        func save(_ item: InteractionRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionRule] {
            return inner.list()
        }
    }

    static func newCachedInteractionRuleStore(_ inner: MemoryInteractionRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionRuleStore {
        return CachedInteractionRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction rules. Empty fields match all.
    final class InteractionRuleQuery {
        var facility: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionRule) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionRule]) -> [InteractionRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionRules(_ store: any InteractionRuleStore, query: InteractionRuleQuery) -> [InteractionRule] {
        return query.apply(store.list())
    }
}

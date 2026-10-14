import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual follow up rules by code.
    protocol ManualFollowUpRuleStore {
        func find(_ code: String) -> ManualFollowUpRule?
        func save(_ item: ManualFollowUpRule)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFollowUpRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFollowUpRuleStore: ManualFollowUpRuleStore {
        var items: [String: ManualFollowUpRule]
        var order: [String]

        init(items: [String: ManualFollowUpRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFollowUpRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFollowUpRule) {
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

        func list() -> [ManualFollowUpRule] {
            var out: [ManualFollowUpRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFollowUpRuleStore() -> any ManualFollowUpRuleStore {
        return MemoryManualFollowUpRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFollowUpRuleStore: ManualFollowUpRuleStore {
        var inner: MemoryManualFollowUpRuleStore
        var cache: TTLCache<ManualFollowUpRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFollowUpRuleStore, cache: TTLCache<ManualFollowUpRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFollowUpRule? {
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

        func save(_ item: ManualFollowUpRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFollowUpRule] {
            return inner.list()
        }
    }

    static func newCachedManualFollowUpRuleStore(_ inner: MemoryManualFollowUpRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFollowUpRuleStore {
        return CachedManualFollowUpRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual follow up rules. Empty fields match all.
    final class ManualFollowUpRuleQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFollowUpRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualFollowUpRule]) -> [ManualFollowUpRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFollowUpRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFollowUpRules(_ store: any ManualFollowUpRuleStore, query: ManualFollowUpRuleQuery) -> [ManualFollowUpRule] {
        return query.apply(store.list())
    }
}

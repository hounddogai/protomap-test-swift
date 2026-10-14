import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up rules by code.
    protocol FollowUpRuleStore {
        func find(_ code: String) -> FollowUpRule?
        func save(_ item: FollowUpRule)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpRuleStore: FollowUpRuleStore {
        var items: [String: FollowUpRule]
        var order: [String]

        init(items: [String: FollowUpRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpRule) {
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

        func list() -> [FollowUpRule] {
            var out: [FollowUpRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpRuleStore() -> any FollowUpRuleStore {
        return MemoryFollowUpRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpRuleStore: FollowUpRuleStore {
        var inner: MemoryFollowUpRuleStore
        var cache: TTLCache<FollowUpRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpRuleStore, cache: TTLCache<FollowUpRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpRule? {
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

        func save(_ item: FollowUpRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpRule] {
            return inner.list()
        }
    }

    static func newCachedFollowUpRuleStore(_ inner: MemoryFollowUpRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpRuleStore {
        return CachedFollowUpRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up rules. Empty fields match all.
    final class FollowUpRuleQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpRule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpRule]) -> [FollowUpRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpRules(_ store: any FollowUpRuleStore, query: FollowUpRuleQuery) -> [FollowUpRule] {
        return query.apply(store.list())
    }
}

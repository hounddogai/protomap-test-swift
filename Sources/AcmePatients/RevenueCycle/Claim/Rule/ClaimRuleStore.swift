import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim rules by code.
    protocol ClaimRuleStore {
        func find(_ code: String) -> ClaimRule?
        func save(_ item: ClaimRule)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimRuleStore: ClaimRuleStore {
        var items: [String: ClaimRule]
        var order: [String]

        init(items: [String: ClaimRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimRule) {
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

        func list() -> [ClaimRule] {
            var out: [ClaimRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimRuleStore() -> any ClaimRuleStore {
        return MemoryClaimRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimRuleStore: ClaimRuleStore {
        var inner: MemoryClaimRuleStore
        var cache: TTLCache<ClaimRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimRuleStore, cache: TTLCache<ClaimRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimRule? {
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

        func save(_ item: ClaimRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimRule] {
            return inner.list()
        }
    }

    static func newCachedClaimRuleStore(_ inner: MemoryClaimRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimRuleStore {
        return CachedClaimRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim rules. Empty fields match all.
    final class ClaimRuleQuery {
        var locale: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minSequence: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimRule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimRule]) -> [ClaimRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimRules(_ store: any ClaimRuleStore, query: ClaimRuleQuery) -> [ClaimRule] {
        return query.apply(store.list())
    }
}

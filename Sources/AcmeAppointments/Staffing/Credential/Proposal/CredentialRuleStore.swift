import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential rules by code.
    protocol CredentialRuleStore {
        func find(_ code: String) -> CredentialRule?
        func save(_ item: CredentialRule)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialRuleStore: CredentialRuleStore {
        var items: [String: CredentialRule]
        var order: [String]

        init(items: [String: CredentialRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialRule) {
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

        func list() -> [CredentialRule] {
            var out: [CredentialRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialRuleStore() -> any CredentialRuleStore {
        return MemoryCredentialRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialRuleStore: CredentialRuleStore {
        var inner: MemoryCredentialRuleStore
        var cache: TTLCache<CredentialRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialRuleStore, cache: TTLCache<CredentialRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialRule? {
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

        func save(_ item: CredentialRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialRule] {
            return inner.list()
        }
    }

    static func newCachedCredentialRuleStore(_ inner: MemoryCredentialRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialRuleStore {
        return CachedCredentialRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential rules. Empty fields match all.
    final class CredentialRuleQuery {
        var locale: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minRate: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialRule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialRule]) -> [CredentialRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialRules(_ store: any CredentialRuleStore, query: CredentialRuleQuery) -> [CredentialRule] {
        return query.apply(store.list())
    }
}

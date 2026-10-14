import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive credential rules by code.
    protocol AdaptiveCredentialRuleStore {
        func find(_ code: String) -> AdaptiveCredentialRule?
        func save(_ item: AdaptiveCredentialRule)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCredentialRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCredentialRuleStore: AdaptiveCredentialRuleStore {
        var items: [String: AdaptiveCredentialRule]
        var order: [String]

        init(items: [String: AdaptiveCredentialRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCredentialRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCredentialRule) {
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

        func list() -> [AdaptiveCredentialRule] {
            var out: [AdaptiveCredentialRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCredentialRuleStore() -> any AdaptiveCredentialRuleStore {
        return MemoryAdaptiveCredentialRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCredentialRuleStore: AdaptiveCredentialRuleStore {
        var inner: MemoryAdaptiveCredentialRuleStore
        var cache: TTLCache<AdaptiveCredentialRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCredentialRuleStore, cache: TTLCache<AdaptiveCredentialRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCredentialRule? {
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

        func save(_ item: AdaptiveCredentialRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCredentialRule] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCredentialRuleStore(_ inner: MemoryAdaptiveCredentialRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCredentialRuleStore {
        return CachedAdaptiveCredentialRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive credential rules. Empty fields match all.
    final class AdaptiveCredentialRuleQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCredentialRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCredentialRule]) -> [AdaptiveCredentialRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCredentialRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCredentialRules(_ store: any AdaptiveCredentialRuleStore, query: AdaptiveCredentialRuleQuery) -> [AdaptiveCredentialRule] {
        return query.apply(store.list())
    }
}

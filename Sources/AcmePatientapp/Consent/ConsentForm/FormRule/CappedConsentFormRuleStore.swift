import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped consent form rules by code.
    protocol CappedConsentFormRuleStore {
        func find(_ code: String) -> CappedConsentFormRule?
        func save(_ item: CappedConsentFormRule)
        func remove(_ code: String) -> Bool
        func list() -> [CappedConsentFormRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedConsentFormRuleStore: CappedConsentFormRuleStore {
        var items: [String: CappedConsentFormRule]
        var order: [String]

        init(items: [String: CappedConsentFormRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedConsentFormRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedConsentFormRule) {
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

        func list() -> [CappedConsentFormRule] {
            var out: [CappedConsentFormRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedConsentFormRuleStore() -> any CappedConsentFormRuleStore {
        return MemoryCappedConsentFormRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedConsentFormRuleStore: CappedConsentFormRuleStore {
        var inner: MemoryCappedConsentFormRuleStore
        var cache: TTLCache<CappedConsentFormRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedConsentFormRuleStore, cache: TTLCache<CappedConsentFormRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedConsentFormRule? {
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

        func save(_ item: CappedConsentFormRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedConsentFormRule] {
            return inner.list()
        }
    }

    static func newCachedCappedConsentFormRuleStore(_ inner: MemoryCappedConsentFormRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedConsentFormRuleStore {
        return CachedCappedConsentFormRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped consent form rules. Empty fields match all.
    final class CappedConsentFormRuleQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedConsentFormRule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedConsentFormRule]) -> [CappedConsentFormRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedConsentFormRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedConsentFormRules(_ store: any CappedConsentFormRuleStore, query: CappedConsentFormRuleQuery) -> [CappedConsentFormRule] {
        return query.apply(store.list())
    }
}

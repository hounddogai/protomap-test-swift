import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness rules by code.
    protocol WitnessRuleStore {
        func find(_ code: String) -> WitnessRule?
        func save(_ item: WitnessRule)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessRuleStore: WitnessRuleStore {
        var items: [String: WitnessRule]
        var order: [String]

        init(items: [String: WitnessRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessRule) {
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

        func list() -> [WitnessRule] {
            var out: [WitnessRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessRuleStore() -> any WitnessRuleStore {
        return MemoryWitnessRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessRuleStore: WitnessRuleStore {
        var inner: MemoryWitnessRuleStore
        var cache: TTLCache<WitnessRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessRuleStore, cache: TTLCache<WitnessRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessRule? {
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

        func save(_ item: WitnessRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessRule] {
            return inner.list()
        }
    }

    static func newCachedWitnessRuleStore(_ inner: MemoryWitnessRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessRuleStore {
        return CachedWitnessRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness rules. Empty fields match all.
    final class WitnessRuleQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessRule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessRule]) -> [WitnessRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessRules(_ store: any WitnessRuleStore, query: WitnessRuleQuery) -> [WitnessRule] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive dispense rules by code.
    protocol AdaptiveDispenseRuleStore {
        func find(_ code: String) -> AdaptiveDispenseRule?
        func save(_ item: AdaptiveDispenseRule)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDispenseRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDispenseRuleStore: AdaptiveDispenseRuleStore {
        var items: [String: AdaptiveDispenseRule]
        var order: [String]

        init(items: [String: AdaptiveDispenseRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDispenseRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDispenseRule) {
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

        func list() -> [AdaptiveDispenseRule] {
            var out: [AdaptiveDispenseRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDispenseRuleStore() -> any AdaptiveDispenseRuleStore {
        return MemoryAdaptiveDispenseRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDispenseRuleStore: AdaptiveDispenseRuleStore {
        var inner: MemoryAdaptiveDispenseRuleStore
        var cache: TTLCache<AdaptiveDispenseRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDispenseRuleStore, cache: TTLCache<AdaptiveDispenseRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDispenseRule? {
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

        func save(_ item: AdaptiveDispenseRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDispenseRule] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDispenseRuleStore(_ inner: MemoryAdaptiveDispenseRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDispenseRuleStore {
        return CachedAdaptiveDispenseRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive dispense rules. Empty fields match all.
    final class AdaptiveDispenseRuleQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDispenseRule) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveDispenseRule]) -> [AdaptiveDispenseRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDispenseRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDispenseRules(_ store: any AdaptiveDispenseRuleStore, query: AdaptiveDispenseRuleQuery) -> [AdaptiveDispenseRule] {
        return query.apply(store.list())
    }
}

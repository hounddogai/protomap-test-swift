import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped closure rules by code.
    protocol CappedClosureRuleStore {
        func find(_ code: String) -> CappedClosureRule?
        func save(_ item: CappedClosureRule)
        func remove(_ code: String) -> Bool
        func list() -> [CappedClosureRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedClosureRuleStore: CappedClosureRuleStore {
        var items: [String: CappedClosureRule]
        var order: [String]

        init(items: [String: CappedClosureRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedClosureRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedClosureRule) {
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

        func list() -> [CappedClosureRule] {
            var out: [CappedClosureRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedClosureRuleStore() -> any CappedClosureRuleStore {
        return MemoryCappedClosureRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedClosureRuleStore: CappedClosureRuleStore {
        var inner: MemoryCappedClosureRuleStore
        var cache: TTLCache<CappedClosureRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedClosureRuleStore, cache: TTLCache<CappedClosureRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedClosureRule? {
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

        func save(_ item: CappedClosureRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedClosureRule] {
            return inner.list()
        }
    }

    static func newCachedCappedClosureRuleStore(_ inner: MemoryCappedClosureRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedClosureRuleStore {
        return CachedCappedClosureRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped closure rules. Empty fields match all.
    final class CappedClosureRuleQuery {
        var source: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCopay: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedClosureRule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedClosureRule]) -> [CappedClosureRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedClosureRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedClosureRules(_ store: any CappedClosureRuleStore, query: CappedClosureRuleQuery) -> [CappedClosureRule] {
        return query.apply(store.list())
    }
}

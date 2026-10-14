import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient care gap rules by code.
    protocol LenientCareGapRuleStore {
        func find(_ code: String) -> LenientCareGapRule?
        func save(_ item: LenientCareGapRule)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareGapRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareGapRuleStore: LenientCareGapRuleStore {
        var items: [String: LenientCareGapRule]
        var order: [String]

        init(items: [String: LenientCareGapRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareGapRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareGapRule) {
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

        func list() -> [LenientCareGapRule] {
            var out: [LenientCareGapRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareGapRuleStore() -> any LenientCareGapRuleStore {
        return MemoryLenientCareGapRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareGapRuleStore: LenientCareGapRuleStore {
        var inner: MemoryLenientCareGapRuleStore
        var cache: TTLCache<LenientCareGapRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareGapRuleStore, cache: TTLCache<LenientCareGapRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareGapRule? {
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

        func save(_ item: LenientCareGapRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareGapRule] {
            return inner.list()
        }
    }

    static func newCachedLenientCareGapRuleStore(_ inner: MemoryLenientCareGapRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareGapRuleStore {
        return CachedLenientCareGapRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care gap rules. Empty fields match all.
    final class LenientCareGapRuleQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareGapRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCareGapRule]) -> [LenientCareGapRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareGapRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareGapRules(_ store: any LenientCareGapRuleStore, query: LenientCareGapRuleQuery) -> [LenientCareGapRule] {
        return query.apply(store.list())
    }
}

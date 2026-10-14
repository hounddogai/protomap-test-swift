import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling substitution rules by code.
    protocol RollingSubstitutionRuleStore {
        func find(_ code: String) -> RollingSubstitutionRule?
        func save(_ item: RollingSubstitutionRule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingSubstitutionRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingSubstitutionRuleStore: RollingSubstitutionRuleStore {
        var items: [String: RollingSubstitutionRule]
        var order: [String]

        init(items: [String: RollingSubstitutionRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingSubstitutionRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingSubstitutionRule) {
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

        func list() -> [RollingSubstitutionRule] {
            var out: [RollingSubstitutionRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingSubstitutionRuleStore() -> any RollingSubstitutionRuleStore {
        return MemoryRollingSubstitutionRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingSubstitutionRuleStore: RollingSubstitutionRuleStore {
        var inner: MemoryRollingSubstitutionRuleStore
        var cache: TTLCache<RollingSubstitutionRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingSubstitutionRuleStore, cache: TTLCache<RollingSubstitutionRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingSubstitutionRule? {
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

        func save(_ item: RollingSubstitutionRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingSubstitutionRule] {
            return inner.list()
        }
    }

    static func newCachedRollingSubstitutionRuleStore(_ inner: MemoryRollingSubstitutionRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingSubstitutionRuleStore {
        return CachedRollingSubstitutionRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling substitution rules. Empty fields match all.
    final class RollingSubstitutionRuleQuery {
        var source: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingSubstitutionRule) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingSubstitutionRule]) -> [RollingSubstitutionRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingSubstitutionRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingSubstitutionRules(_ store: any RollingSubstitutionRuleStore, query: RollingSubstitutionRuleQuery) -> [RollingSubstitutionRule] {
        return query.apply(store.list())
    }
}

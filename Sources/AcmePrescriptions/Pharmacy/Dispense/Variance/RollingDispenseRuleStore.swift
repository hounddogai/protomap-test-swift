import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling dispense rules by code.
    protocol RollingDispenseRuleStore {
        func find(_ code: String) -> RollingDispenseRule?
        func save(_ item: RollingDispenseRule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDispenseRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDispenseRuleStore: RollingDispenseRuleStore {
        var items: [String: RollingDispenseRule]
        var order: [String]

        init(items: [String: RollingDispenseRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDispenseRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDispenseRule) {
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

        func list() -> [RollingDispenseRule] {
            var out: [RollingDispenseRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDispenseRuleStore() -> any RollingDispenseRuleStore {
        return MemoryRollingDispenseRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDispenseRuleStore: RollingDispenseRuleStore {
        var inner: MemoryRollingDispenseRuleStore
        var cache: TTLCache<RollingDispenseRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDispenseRuleStore, cache: TTLCache<RollingDispenseRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDispenseRule? {
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

        func save(_ item: RollingDispenseRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDispenseRule] {
            return inner.list()
        }
    }

    static func newCachedRollingDispenseRuleStore(_ inner: MemoryRollingDispenseRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDispenseRuleStore {
        return CachedRollingDispenseRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling dispense rules. Empty fields match all.
    final class RollingDispenseRuleQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDispenseRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RollingDispenseRule]) -> [RollingDispenseRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDispenseRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDispenseRules(_ store: any RollingDispenseRuleStore, query: RollingDispenseRuleQuery) -> [RollingDispenseRule] {
        return query.apply(store.list())
    }
}

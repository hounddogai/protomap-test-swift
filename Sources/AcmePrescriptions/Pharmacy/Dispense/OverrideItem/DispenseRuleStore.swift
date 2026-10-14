import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense rules by code.
    protocol DispenseRuleStore {
        func find(_ code: String) -> DispenseRule?
        func save(_ item: DispenseRule)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseRuleStore: DispenseRuleStore {
        var items: [String: DispenseRule]
        var order: [String]

        init(items: [String: DispenseRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseRule) {
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

        func list() -> [DispenseRule] {
            var out: [DispenseRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseRuleStore() -> any DispenseRuleStore {
        return MemoryDispenseRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseRuleStore: DispenseRuleStore {
        var inner: MemoryDispenseRuleStore
        var cache: TTLCache<DispenseRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseRuleStore, cache: TTLCache<DispenseRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseRule? {
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

        func save(_ item: DispenseRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseRule] {
            return inner.list()
        }
    }

    static func newCachedDispenseRuleStore(_ inner: MemoryDispenseRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseRuleStore {
        return CachedDispenseRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense rules. Empty fields match all.
    final class DispenseRuleQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseRule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseRule]) -> [DispenseRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseRules(_ store: any DispenseRuleStore, query: DispenseRuleQuery) -> [DispenseRule] {
        return query.apply(store.list())
    }
}

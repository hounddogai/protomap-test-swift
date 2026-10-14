import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered outreach rules by code.
    protocol TieredOutreachRuleStore {
        func find(_ code: String) -> TieredOutreachRule?
        func save(_ item: TieredOutreachRule)
        func remove(_ code: String) -> Bool
        func list() -> [TieredOutreachRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredOutreachRuleStore: TieredOutreachRuleStore {
        var items: [String: TieredOutreachRule]
        var order: [String]

        init(items: [String: TieredOutreachRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredOutreachRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredOutreachRule) {
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

        func list() -> [TieredOutreachRule] {
            var out: [TieredOutreachRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredOutreachRuleStore() -> any TieredOutreachRuleStore {
        return MemoryTieredOutreachRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredOutreachRuleStore: TieredOutreachRuleStore {
        var inner: MemoryTieredOutreachRuleStore
        var cache: TTLCache<TieredOutreachRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredOutreachRuleStore, cache: TTLCache<TieredOutreachRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredOutreachRule? {
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

        func save(_ item: TieredOutreachRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredOutreachRule] {
            return inner.list()
        }
    }

    static func newCachedTieredOutreachRuleStore(_ inner: MemoryTieredOutreachRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredOutreachRuleStore {
        return CachedTieredOutreachRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered outreach rules. Empty fields match all.
    final class TieredOutreachRuleQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredOutreachRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredOutreachRule]) -> [TieredOutreachRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredOutreachRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredOutreachRules(_ store: any TieredOutreachRuleStore, query: TieredOutreachRuleQuery) -> [TieredOutreachRule] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global care protocol rules by code.
    protocol GlobalCareProtocolRuleStore {
        func find(_ code: String) -> GlobalCareProtocolRule?
        func save(_ item: GlobalCareProtocolRule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCareProtocolRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCareProtocolRuleStore: GlobalCareProtocolRuleStore {
        var items: [String: GlobalCareProtocolRule]
        var order: [String]

        init(items: [String: GlobalCareProtocolRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCareProtocolRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCareProtocolRule) {
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

        func list() -> [GlobalCareProtocolRule] {
            var out: [GlobalCareProtocolRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCareProtocolRuleStore() -> any GlobalCareProtocolRuleStore {
        return MemoryGlobalCareProtocolRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCareProtocolRuleStore: GlobalCareProtocolRuleStore {
        var inner: MemoryGlobalCareProtocolRuleStore
        var cache: TTLCache<GlobalCareProtocolRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCareProtocolRuleStore, cache: TTLCache<GlobalCareProtocolRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCareProtocolRule? {
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

        func save(_ item: GlobalCareProtocolRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCareProtocolRule] {
            return inner.list()
        }
    }

    static func newCachedGlobalCareProtocolRuleStore(_ inner: MemoryGlobalCareProtocolRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCareProtocolRuleStore {
        return CachedGlobalCareProtocolRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global care protocol rules. Empty fields match all.
    final class GlobalCareProtocolRuleQuery {
        var category: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCareProtocolRule) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCareProtocolRule]) -> [GlobalCareProtocolRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCareProtocolRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCareProtocolRules(_ store: any GlobalCareProtocolRuleStore, query: GlobalCareProtocolRuleQuery) -> [GlobalCareProtocolRule] {
        return query.apply(store.list())
    }
}

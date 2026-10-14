import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered eligibility templates by code.
    protocol TieredEligibilityTemplateStore {
        func find(_ code: String) -> TieredEligibilityTemplate?
        func save(_ item: TieredEligibilityTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [TieredEligibilityTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredEligibilityTemplateStore: TieredEligibilityTemplateStore {
        var items: [String: TieredEligibilityTemplate]
        var order: [String]

        init(items: [String: TieredEligibilityTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredEligibilityTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredEligibilityTemplate) {
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

        func list() -> [TieredEligibilityTemplate] {
            var out: [TieredEligibilityTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredEligibilityTemplateStore() -> any TieredEligibilityTemplateStore {
        return MemoryTieredEligibilityTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredEligibilityTemplateStore: TieredEligibilityTemplateStore {
        var inner: MemoryTieredEligibilityTemplateStore
        var cache: TTLCache<TieredEligibilityTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredEligibilityTemplateStore, cache: TTLCache<TieredEligibilityTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredEligibilityTemplate? {
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

        func save(_ item: TieredEligibilityTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredEligibilityTemplate] {
            return inner.list()
        }
    }

    static func newCachedTieredEligibilityTemplateStore(_ inner: MemoryTieredEligibilityTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredEligibilityTemplateStore {
        return CachedTieredEligibilityTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered eligibility templates. Empty fields match all.
    final class TieredEligibilityTemplateQuery {
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

        func matches(_ item: TieredEligibilityTemplate) -> Bool {
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

        func apply(_ items: [TieredEligibilityTemplate]) -> [TieredEligibilityTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredEligibilityTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredEligibilityTemplates(_ store: any TieredEligibilityTemplateStore, query: TieredEligibilityTemplateQuery) -> [TieredEligibilityTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted risk score templates by code.
    protocol WeightedRiskScoreTemplateStore {
        func find(_ code: String) -> WeightedRiskScoreTemplate?
        func save(_ item: WeightedRiskScoreTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedRiskScoreTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedRiskScoreTemplateStore: WeightedRiskScoreTemplateStore {
        var items: [String: WeightedRiskScoreTemplate]
        var order: [String]

        init(items: [String: WeightedRiskScoreTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedRiskScoreTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedRiskScoreTemplate) {
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

        func list() -> [WeightedRiskScoreTemplate] {
            var out: [WeightedRiskScoreTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedRiskScoreTemplateStore() -> any WeightedRiskScoreTemplateStore {
        return MemoryWeightedRiskScoreTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedRiskScoreTemplateStore: WeightedRiskScoreTemplateStore {
        var inner: MemoryWeightedRiskScoreTemplateStore
        var cache: TTLCache<WeightedRiskScoreTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedRiskScoreTemplateStore, cache: TTLCache<WeightedRiskScoreTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedRiskScoreTemplate? {
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

        func save(_ item: WeightedRiskScoreTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedRiskScoreTemplate] {
            return inner.list()
        }
    }

    static func newCachedWeightedRiskScoreTemplateStore(_ inner: MemoryWeightedRiskScoreTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedRiskScoreTemplateStore {
        return CachedWeightedRiskScoreTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted risk score templates. Empty fields match all.
    final class WeightedRiskScoreTemplateQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedRiskScoreTemplate) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedRiskScoreTemplate]) -> [WeightedRiskScoreTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedRiskScoreTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedRiskScoreTemplates(_ store: any WeightedRiskScoreTemplateStore, query: WeightedRiskScoreTemplateQuery) -> [WeightedRiskScoreTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score templates by code.
    protocol RiskScoreTemplateStore {
        func find(_ code: String) -> RiskScoreTemplate?
        func save(_ item: RiskScoreTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreTemplateStore: RiskScoreTemplateStore {
        var items: [String: RiskScoreTemplate]
        var order: [String]

        init(items: [String: RiskScoreTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreTemplate) {
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

        func list() -> [RiskScoreTemplate] {
            var out: [RiskScoreTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreTemplateStore() -> any RiskScoreTemplateStore {
        return MemoryRiskScoreTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreTemplateStore: RiskScoreTemplateStore {
        var inner: MemoryRiskScoreTemplateStore
        var cache: TTLCache<RiskScoreTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreTemplateStore, cache: TTLCache<RiskScoreTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreTemplate? {
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

        func save(_ item: RiskScoreTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreTemplate] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreTemplateStore(_ inner: MemoryRiskScoreTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreTemplateStore {
        return CachedRiskScoreTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score templates. Empty fields match all.
    final class RiskScoreTemplateQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreTemplate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [RiskScoreTemplate]) -> [RiskScoreTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreTemplates(_ store: any RiskScoreTemplateStore, query: RiskScoreTemplateQuery) -> [RiskScoreTemplate] {
        return query.apply(store.list())
    }
}

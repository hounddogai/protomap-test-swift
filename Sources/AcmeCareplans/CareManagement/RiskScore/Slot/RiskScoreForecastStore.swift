import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score forecasts by code.
    protocol RiskScoreForecastStore {
        func find(_ code: String) -> RiskScoreForecast?
        func save(_ item: RiskScoreForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreForecastStore: RiskScoreForecastStore {
        var items: [String: RiskScoreForecast]
        var order: [String]

        init(items: [String: RiskScoreForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreForecast) {
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

        func list() -> [RiskScoreForecast] {
            var out: [RiskScoreForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreForecastStore() -> any RiskScoreForecastStore {
        return MemoryRiskScoreForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreForecastStore: RiskScoreForecastStore {
        var inner: MemoryRiskScoreForecastStore
        var cache: TTLCache<RiskScoreForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreForecastStore, cache: TTLCache<RiskScoreForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreForecast? {
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

        func save(_ item: RiskScoreForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreForecast] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreForecastStore(_ inner: MemoryRiskScoreForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreForecastStore {
        return CachedRiskScoreForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score forecasts. Empty fields match all.
    final class RiskScoreForecastQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RiskScoreForecast]) -> [RiskScoreForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreForecasts(_ store: any RiskScoreForecastStore, query: RiskScoreForecastQuery) -> [RiskScoreForecast] {
        return query.apply(store.list())
    }
}

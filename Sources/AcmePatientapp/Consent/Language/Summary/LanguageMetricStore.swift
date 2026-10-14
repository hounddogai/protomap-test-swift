import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language metrics by code.
    protocol LanguageMetricStore {
        func find(_ code: String) -> LanguageMetric?
        func save(_ item: LanguageMetric)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageMetricStore: LanguageMetricStore {
        var items: [String: LanguageMetric]
        var order: [String]

        init(items: [String: LanguageMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageMetric) {
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

        func list() -> [LanguageMetric] {
            var out: [LanguageMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageMetricStore() -> any LanguageMetricStore {
        return MemoryLanguageMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageMetricStore: LanguageMetricStore {
        var inner: MemoryLanguageMetricStore
        var cache: TTLCache<LanguageMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageMetricStore, cache: TTLCache<LanguageMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageMetric? {
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

        func save(_ item: LanguageMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageMetric] {
            return inner.list()
        }
    }

    static func newCachedLanguageMetricStore(_ inner: MemoryLanguageMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageMetricStore {
        return CachedLanguageMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language metrics. Empty fields match all.
    final class LanguageMetricQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageMetric) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageMetric]) -> [LanguageMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageMetrics(_ store: any LanguageMetricStore, query: LanguageMetricQuery) -> [LanguageMetric] {
        return query.apply(store.list())
    }
}

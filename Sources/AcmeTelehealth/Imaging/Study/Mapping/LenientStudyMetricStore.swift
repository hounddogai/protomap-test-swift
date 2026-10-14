import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient study metrics by code.
    protocol LenientStudyMetricStore {
        func find(_ code: String) -> LenientStudyMetric?
        func save(_ item: LenientStudyMetric)
        func remove(_ code: String) -> Bool
        func list() -> [LenientStudyMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientStudyMetricStore: LenientStudyMetricStore {
        var items: [String: LenientStudyMetric]
        var order: [String]

        init(items: [String: LenientStudyMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientStudyMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientStudyMetric) {
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

        func list() -> [LenientStudyMetric] {
            var out: [LenientStudyMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientStudyMetricStore() -> any LenientStudyMetricStore {
        return MemoryLenientStudyMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientStudyMetricStore: LenientStudyMetricStore {
        var inner: MemoryLenientStudyMetricStore
        var cache: TTLCache<LenientStudyMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientStudyMetricStore, cache: TTLCache<LenientStudyMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientStudyMetric? {
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

        func save(_ item: LenientStudyMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientStudyMetric] {
            return inner.list()
        }
    }

    static func newCachedLenientStudyMetricStore(_ inner: MemoryLenientStudyMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientStudyMetricStore {
        return CachedLenientStudyMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient study metrics. Empty fields match all.
    final class LenientStudyMetricQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientStudyMetric) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientStudyMetric]) -> [LenientStudyMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientStudyMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientStudyMetrics(_ store: any LenientStudyMetricStore, query: LenientStudyMetricQuery) -> [LenientStudyMetric] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study metrics by code.
    protocol StudyMetricStore {
        func find(_ code: String) -> StudyMetric?
        func save(_ item: StudyMetric)
        func remove(_ code: String) -> Bool
        func list() -> [StudyMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyMetricStore: StudyMetricStore {
        var items: [String: StudyMetric]
        var order: [String]

        init(items: [String: StudyMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyMetric) {
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

        func list() -> [StudyMetric] {
            var out: [StudyMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyMetricStore() -> any StudyMetricStore {
        return MemoryStudyMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyMetricStore: StudyMetricStore {
        var inner: MemoryStudyMetricStore
        var cache: TTLCache<StudyMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyMetricStore, cache: TTLCache<StudyMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyMetric? {
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

        func save(_ item: StudyMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyMetric] {
            return inner.list()
        }
    }

    static func newCachedStudyMetricStore(_ inner: MemoryStudyMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyMetricStore {
        return CachedStudyMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study metrics. Empty fields match all.
    final class StudyMetricQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyMetric]) -> [StudyMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyMetrics(_ store: any StudyMetricStore, query: StudyMetricQuery) -> [StudyMetric] {
        return query.apply(store.list())
    }
}

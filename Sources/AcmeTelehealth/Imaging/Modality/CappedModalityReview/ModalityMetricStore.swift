import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality metrics by code.
    protocol ModalityMetricStore {
        func find(_ code: String) -> ModalityMetric?
        func save(_ item: ModalityMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityMetricStore: ModalityMetricStore {
        var items: [String: ModalityMetric]
        var order: [String]

        init(items: [String: ModalityMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityMetric) {
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

        func list() -> [ModalityMetric] {
            var out: [ModalityMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityMetricStore() -> any ModalityMetricStore {
        return MemoryModalityMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityMetricStore: ModalityMetricStore {
        var inner: MemoryModalityMetricStore
        var cache: TTLCache<ModalityMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityMetricStore, cache: TTLCache<ModalityMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityMetric? {
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

        func save(_ item: ModalityMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityMetric] {
            return inner.list()
        }
    }

    static func newCachedModalityMetricStore(_ inner: MemoryModalityMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityMetricStore {
        return CachedModalityMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality metrics. Empty fields match all.
    final class ModalityMetricQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityMetric]) -> [ModalityMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityMetrics(_ store: any ModalityMetricStore, query: ModalityMetricQuery) -> [ModalityMetric] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read estimates by code.
    protocol ReadEstimateStore {
        func find(_ code: String) -> ReadEstimate?
        func save(_ item: ReadEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ReadEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadEstimateStore: ReadEstimateStore {
        var items: [String: ReadEstimate]
        var order: [String]

        init(items: [String: ReadEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadEstimate) {
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

        func list() -> [ReadEstimate] {
            var out: [ReadEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadEstimateStore() -> any ReadEstimateStore {
        return MemoryReadEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadEstimateStore: ReadEstimateStore {
        var inner: MemoryReadEstimateStore
        var cache: TTLCache<ReadEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadEstimateStore, cache: TTLCache<ReadEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadEstimate? {
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

        func save(_ item: ReadEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadEstimate] {
            return inner.list()
        }
    }

    static func newCachedReadEstimateStore(_ inner: MemoryReadEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadEstimateStore {
        return CachedReadEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read estimates. Empty fields match all.
    final class ReadEstimateQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadEstimate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadEstimate]) -> [ReadEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadEstimates(_ store: any ReadEstimateStore, query: ReadEstimateQuery) -> [ReadEstimate] {
        return query.apply(store.list())
    }
}

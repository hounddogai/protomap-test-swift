import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality estimates by code.
    protocol ModalityEstimateStore {
        func find(_ code: String) -> ModalityEstimate?
        func save(_ item: ModalityEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityEstimateStore: ModalityEstimateStore {
        var items: [String: ModalityEstimate]
        var order: [String]

        init(items: [String: ModalityEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityEstimate) {
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

        func list() -> [ModalityEstimate] {
            var out: [ModalityEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityEstimateStore() -> any ModalityEstimateStore {
        return MemoryModalityEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityEstimateStore: ModalityEstimateStore {
        var inner: MemoryModalityEstimateStore
        var cache: TTLCache<ModalityEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityEstimateStore, cache: TTLCache<ModalityEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityEstimate? {
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

        func save(_ item: ModalityEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityEstimate] {
            return inner.list()
        }
    }

    static func newCachedModalityEstimateStore(_ inner: MemoryModalityEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityEstimateStore {
        return CachedModalityEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality estimates. Empty fields match all.
    final class ModalityEstimateQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityEstimate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityEstimate]) -> [ModalityEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityEstimates(_ store: any ModalityEstimateStore, query: ModalityEstimateQuery) -> [ModalityEstimate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense estimates by code.
    protocol DispenseEstimateStore {
        func find(_ code: String) -> DispenseEstimate?
        func save(_ item: DispenseEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseEstimateStore: DispenseEstimateStore {
        var items: [String: DispenseEstimate]
        var order: [String]

        init(items: [String: DispenseEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseEstimate) {
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

        func list() -> [DispenseEstimate] {
            var out: [DispenseEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseEstimateStore() -> any DispenseEstimateStore {
        return MemoryDispenseEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseEstimateStore: DispenseEstimateStore {
        var inner: MemoryDispenseEstimateStore
        var cache: TTLCache<DispenseEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseEstimateStore, cache: TTLCache<DispenseEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseEstimate? {
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

        func save(_ item: DispenseEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseEstimate] {
            return inner.list()
        }
    }

    static func newCachedDispenseEstimateStore(_ inner: MemoryDispenseEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseEstimateStore {
        return CachedDispenseEstimateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense estimates. Empty fields match all.
    final class DispenseEstimateQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseEstimate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseEstimate]) -> [DispenseEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseEstimates(_ store: any DispenseEstimateStore, query: DispenseEstimateQuery) -> [DispenseEstimate] {
        return query.apply(store.list())
    }
}

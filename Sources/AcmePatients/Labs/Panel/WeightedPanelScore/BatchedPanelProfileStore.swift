import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched panel profiles by code.
    protocol BatchedPanelProfileStore {
        func find(_ code: String) -> BatchedPanelProfile?
        func save(_ item: BatchedPanelProfile)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedPanelProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedPanelProfileStore: BatchedPanelProfileStore {
        var items: [String: BatchedPanelProfile]
        var order: [String]

        init(items: [String: BatchedPanelProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedPanelProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedPanelProfile) {
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

        func list() -> [BatchedPanelProfile] {
            var out: [BatchedPanelProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedPanelProfileStore() -> any BatchedPanelProfileStore {
        return MemoryBatchedPanelProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedPanelProfileStore: BatchedPanelProfileStore {
        var inner: MemoryBatchedPanelProfileStore
        var cache: TTLCache<BatchedPanelProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedPanelProfileStore, cache: TTLCache<BatchedPanelProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedPanelProfile? {
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

        func save(_ item: BatchedPanelProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedPanelProfile] {
            return inner.list()
        }
    }

    static func newCachedBatchedPanelProfileStore(_ inner: MemoryBatchedPanelProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedPanelProfileStore {
        return CachedBatchedPanelProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched panel profiles. Empty fields match all.
    final class BatchedPanelProfileQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedPanelProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedPanelProfile]) -> [BatchedPanelProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedPanelProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedPanelProfiles(_ store: any BatchedPanelProfileStore, query: BatchedPanelProfileQuery) -> [BatchedPanelProfile] {
        return query.apply(store.list())
    }
}

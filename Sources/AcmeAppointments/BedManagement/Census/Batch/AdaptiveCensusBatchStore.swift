import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive census batches by code.
    protocol AdaptiveCensusBatchStore {
        func find(_ code: String) -> AdaptiveCensusBatch?
        func save(_ item: AdaptiveCensusBatch)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCensusBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCensusBatchStore: AdaptiveCensusBatchStore {
        var items: [String: AdaptiveCensusBatch]
        var order: [String]

        init(items: [String: AdaptiveCensusBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCensusBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCensusBatch) {
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

        func list() -> [AdaptiveCensusBatch] {
            var out: [AdaptiveCensusBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCensusBatchStore() -> any AdaptiveCensusBatchStore {
        return MemoryAdaptiveCensusBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCensusBatchStore: AdaptiveCensusBatchStore {
        var inner: MemoryAdaptiveCensusBatchStore
        var cache: TTLCache<AdaptiveCensusBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCensusBatchStore, cache: TTLCache<AdaptiveCensusBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCensusBatch? {
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

        func save(_ item: AdaptiveCensusBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCensusBatch] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCensusBatchStore(_ inner: MemoryAdaptiveCensusBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCensusBatchStore {
        return CachedAdaptiveCensusBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive census batches. Empty fields match all.
    final class AdaptiveCensusBatchQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCensusBatch) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveCensusBatch]) -> [AdaptiveCensusBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCensusBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCensusBatches(_ store: any AdaptiveCensusBatchStore, query: AdaptiveCensusBatchQuery) -> [AdaptiveCensusBatch] {
        return query.apply(store.list())
    }
}

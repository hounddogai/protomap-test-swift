import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness batches by code.
    protocol WitnessBatchStore {
        func find(_ code: String) -> WitnessBatch?
        func save(_ item: WitnessBatch)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessBatchStore: WitnessBatchStore {
        var items: [String: WitnessBatch]
        var order: [String]

        init(items: [String: WitnessBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessBatch) {
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

        func list() -> [WitnessBatch] {
            var out: [WitnessBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessBatchStore() -> any WitnessBatchStore {
        return MemoryWitnessBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessBatchStore: WitnessBatchStore {
        var inner: MemoryWitnessBatchStore
        var cache: TTLCache<WitnessBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessBatchStore, cache: TTLCache<WitnessBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessBatch? {
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

        func save(_ item: WitnessBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessBatch] {
            return inner.list()
        }
    }

    static func newCachedWitnessBatchStore(_ inner: MemoryWitnessBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessBatchStore {
        return CachedWitnessBatchStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness batches. Empty fields match all.
    final class WitnessBatchQuery {
        var source: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessBatch) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessBatch]) -> [WitnessBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessBatches(_ store: any WitnessBatchStore, query: WitnessBatchQuery) -> [WitnessBatch] {
        return query.apply(store.list())
    }
}

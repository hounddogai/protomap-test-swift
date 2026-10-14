import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient census batches by code.
    protocol LenientCensusBatchStore {
        func find(_ code: String) -> LenientCensusBatch?
        func save(_ item: LenientCensusBatch)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCensusBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCensusBatchStore: LenientCensusBatchStore {
        var items: [String: LenientCensusBatch]
        var order: [String]

        init(items: [String: LenientCensusBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCensusBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCensusBatch) {
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

        func list() -> [LenientCensusBatch] {
            var out: [LenientCensusBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCensusBatchStore() -> any LenientCensusBatchStore {
        return MemoryLenientCensusBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCensusBatchStore: LenientCensusBatchStore {
        var inner: MemoryLenientCensusBatchStore
        var cache: TTLCache<LenientCensusBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCensusBatchStore, cache: TTLCache<LenientCensusBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCensusBatch? {
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

        func save(_ item: LenientCensusBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCensusBatch] {
            return inner.list()
        }
    }

    static func newCachedLenientCensusBatchStore(_ inner: MemoryLenientCensusBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCensusBatchStore {
        return CachedLenientCensusBatchStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient census batches. Empty fields match all.
    final class LenientCensusBatchQuery {
        var channel: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minLimit: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCensusBatch) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCensusBatch]) -> [LenientCensusBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCensusBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCensusBatches(_ store: any LenientCensusBatchStore, query: LenientCensusBatchQuery) -> [LenientCensusBatch] {
        return query.apply(store.list())
    }
}

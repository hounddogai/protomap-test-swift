import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge batches by code.
    protocol ChargeBatchStore {
        func find(_ code: String) -> ChargeBatch?
        func save(_ item: ChargeBatch)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeBatchStore: ChargeBatchStore {
        var items: [String: ChargeBatch]
        var order: [String]

        init(items: [String: ChargeBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeBatch) {
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

        func list() -> [ChargeBatch] {
            var out: [ChargeBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeBatchStore() -> any ChargeBatchStore {
        return MemoryChargeBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeBatchStore: ChargeBatchStore {
        var inner: MemoryChargeBatchStore
        var cache: TTLCache<ChargeBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeBatchStore, cache: TTLCache<ChargeBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeBatch? {
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

        func save(_ item: ChargeBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeBatch] {
            return inner.list()
        }
    }

    static func newCachedChargeBatchStore(_ inner: MemoryChargeBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeBatchStore {
        return CachedChargeBatchStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge batches. Empty fields match all.
    final class ChargeBatchQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeBatch]) -> [ChargeBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeBatches(_ store: any ChargeBatchStore, query: ChargeBatchQuery) -> [ChargeBatch] {
        return query.apply(store.list())
    }
}

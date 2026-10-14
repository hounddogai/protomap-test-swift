import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set checkpoints by code.
    protocol OrderSetCheckpointStore {
        func find(_ code: String) -> OrderSetCheckpoint?
        func save(_ item: OrderSetCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetCheckpointStore: OrderSetCheckpointStore {
        var items: [String: OrderSetCheckpoint]
        var order: [String]

        init(items: [String: OrderSetCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetCheckpoint) {
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

        func list() -> [OrderSetCheckpoint] {
            var out: [OrderSetCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetCheckpointStore() -> any OrderSetCheckpointStore {
        return MemoryOrderSetCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetCheckpointStore: OrderSetCheckpointStore {
        var inner: MemoryOrderSetCheckpointStore
        var cache: TTLCache<OrderSetCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetCheckpointStore, cache: TTLCache<OrderSetCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetCheckpoint? {
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

        func save(_ item: OrderSetCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedOrderSetCheckpointStore(_ inner: MemoryOrderSetCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetCheckpointStore {
        return CachedOrderSetCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set checkpoints. Empty fields match all.
    final class OrderSetCheckpointQuery {
        var locale: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetCheckpoint]) -> [OrderSetCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetCheckpoints(_ store: any OrderSetCheckpointStore, query: OrderSetCheckpointQuery) -> [OrderSetCheckpoint] {
        return query.apply(store.list())
    }
}

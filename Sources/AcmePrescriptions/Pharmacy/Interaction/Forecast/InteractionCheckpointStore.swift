import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction checkpoints by code.
    protocol InteractionCheckpointStore {
        func find(_ code: String) -> InteractionCheckpoint?
        func save(_ item: InteractionCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionCheckpointStore: InteractionCheckpointStore {
        var items: [String: InteractionCheckpoint]
        var order: [String]

        init(items: [String: InteractionCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionCheckpoint) {
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

        func list() -> [InteractionCheckpoint] {
            var out: [InteractionCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionCheckpointStore() -> any InteractionCheckpointStore {
        return MemoryInteractionCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionCheckpointStore: InteractionCheckpointStore {
        var inner: MemoryInteractionCheckpointStore
        var cache: TTLCache<InteractionCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionCheckpointStore, cache: TTLCache<InteractionCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionCheckpoint? {
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

        func save(_ item: InteractionCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedInteractionCheckpointStore(_ inner: MemoryInteractionCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionCheckpointStore {
        return CachedInteractionCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction checkpoints. Empty fields match all.
    final class InteractionCheckpointQuery {
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

        func matches(_ item: InteractionCheckpoint) -> Bool {
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

        func apply(_ items: [InteractionCheckpoint]) -> [InteractionCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionCheckpoints(_ store: any InteractionCheckpointStore, query: InteractionCheckpointQuery) -> [InteractionCheckpoint] {
        return query.apply(store.list())
    }
}

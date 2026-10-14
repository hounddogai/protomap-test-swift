import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory checkpoints by code.
    protocol InventoryCheckpointStore {
        func find(_ code: String) -> InventoryCheckpoint?
        func save(_ item: InventoryCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryCheckpointStore: InventoryCheckpointStore {
        var items: [String: InventoryCheckpoint]
        var order: [String]

        init(items: [String: InventoryCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryCheckpoint) {
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

        func list() -> [InventoryCheckpoint] {
            var out: [InventoryCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryCheckpointStore() -> any InventoryCheckpointStore {
        return MemoryInventoryCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryCheckpointStore: InventoryCheckpointStore {
        var inner: MemoryInventoryCheckpointStore
        var cache: TTLCache<InventoryCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryCheckpointStore, cache: TTLCache<InventoryCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryCheckpoint? {
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

        func save(_ item: InventoryCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedInventoryCheckpointStore(_ inner: MemoryInventoryCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryCheckpointStore {
        return CachedInventoryCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory checkpoints. Empty fields match all.
    final class InventoryCheckpointQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [InventoryCheckpoint]) -> [InventoryCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryCheckpoints(_ store: any InventoryCheckpointStore, query: InventoryCheckpointQuery) -> [InventoryCheckpoint] {
        return query.apply(store.list())
    }
}

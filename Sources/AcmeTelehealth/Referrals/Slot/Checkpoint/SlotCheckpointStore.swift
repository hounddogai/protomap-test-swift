import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot checkpoints by code.
    protocol SlotCheckpointStore {
        func find(_ code: String) -> SlotCheckpoint?
        func save(_ item: SlotCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [SlotCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotCheckpointStore: SlotCheckpointStore {
        var items: [String: SlotCheckpoint]
        var order: [String]

        init(items: [String: SlotCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotCheckpoint) {
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

        func list() -> [SlotCheckpoint] {
            var out: [SlotCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotCheckpointStore() -> any SlotCheckpointStore {
        return MemorySlotCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotCheckpointStore: SlotCheckpointStore {
        var inner: MemorySlotCheckpointStore
        var cache: TTLCache<SlotCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotCheckpointStore, cache: TTLCache<SlotCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotCheckpoint? {
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

        func save(_ item: SlotCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedSlotCheckpointStore(_ inner: MemorySlotCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotCheckpointStore {
        return CachedSlotCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot checkpoints. Empty fields match all.
    final class SlotCheckpointQuery {
        var category: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minWeight: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotCheckpoint) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [SlotCheckpoint]) -> [SlotCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotCheckpoints(_ store: any SlotCheckpointStore, query: SlotCheckpointQuery) -> [SlotCheckpoint] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan checkpoints by code.
    protocol DischargePlanCheckpointStore {
        func find(_ code: String) -> DischargePlanCheckpoint?
        func save(_ item: DischargePlanCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanCheckpointStore: DischargePlanCheckpointStore {
        var items: [String: DischargePlanCheckpoint]
        var order: [String]

        init(items: [String: DischargePlanCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanCheckpoint) {
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

        func list() -> [DischargePlanCheckpoint] {
            var out: [DischargePlanCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanCheckpointStore() -> any DischargePlanCheckpointStore {
        return MemoryDischargePlanCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanCheckpointStore: DischargePlanCheckpointStore {
        var inner: MemoryDischargePlanCheckpointStore
        var cache: TTLCache<DischargePlanCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanCheckpointStore, cache: TTLCache<DischargePlanCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanCheckpoint? {
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

        func save(_ item: DischargePlanCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanCheckpointStore(_ inner: MemoryDischargePlanCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanCheckpointStore {
        return CachedDischargePlanCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan checkpoints. Empty fields match all.
    final class DischargePlanCheckpointQuery {
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

        func matches(_ item: DischargePlanCheckpoint) -> Bool {
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

        func apply(_ items: [DischargePlanCheckpoint]) -> [DischargePlanCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanCheckpoints(_ store: any DischargePlanCheckpointStore, query: DischargePlanCheckpointQuery) -> [DischargePlanCheckpoint] {
        return query.apply(store.list())
    }
}

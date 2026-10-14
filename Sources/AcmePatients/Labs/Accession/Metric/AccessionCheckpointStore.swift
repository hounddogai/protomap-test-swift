import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession checkpoints by code.
    protocol AccessionCheckpointStore {
        func find(_ code: String) -> AccessionCheckpoint?
        func save(_ item: AccessionCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionCheckpointStore: AccessionCheckpointStore {
        var items: [String: AccessionCheckpoint]
        var order: [String]

        init(items: [String: AccessionCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionCheckpoint) {
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

        func list() -> [AccessionCheckpoint] {
            var out: [AccessionCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionCheckpointStore() -> any AccessionCheckpointStore {
        return MemoryAccessionCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionCheckpointStore: AccessionCheckpointStore {
        var inner: MemoryAccessionCheckpointStore
        var cache: TTLCache<AccessionCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionCheckpointStore, cache: TTLCache<AccessionCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionCheckpoint? {
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

        func save(_ item: AccessionCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedAccessionCheckpointStore(_ inner: MemoryAccessionCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionCheckpointStore {
        return CachedAccessionCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession checkpoints. Empty fields match all.
    final class AccessionCheckpointQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionCheckpoint]) -> [AccessionCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionCheckpoints(_ store: any AccessionCheckpointStore, query: AccessionCheckpointQuery) -> [AccessionCheckpoint] {
        return query.apply(store.list())
    }
}

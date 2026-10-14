import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift checkpoints by code.
    protocol ShiftCheckpointStore {
        func find(_ code: String) -> ShiftCheckpoint?
        func save(_ item: ShiftCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftCheckpointStore: ShiftCheckpointStore {
        var items: [String: ShiftCheckpoint]
        var order: [String]

        init(items: [String: ShiftCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftCheckpoint) {
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

        func list() -> [ShiftCheckpoint] {
            var out: [ShiftCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftCheckpointStore() -> any ShiftCheckpointStore {
        return MemoryShiftCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftCheckpointStore: ShiftCheckpointStore {
        var inner: MemoryShiftCheckpointStore
        var cache: TTLCache<ShiftCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftCheckpointStore, cache: TTLCache<ShiftCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftCheckpoint? {
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

        func save(_ item: ShiftCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedShiftCheckpointStore(_ inner: MemoryShiftCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftCheckpointStore {
        return CachedShiftCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift checkpoints. Empty fields match all.
    final class ShiftCheckpointQuery {
        var segment: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftCheckpoint) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftCheckpoint]) -> [ShiftCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftCheckpoints(_ store: any ShiftCheckpointStore, query: ShiftCheckpointQuery) -> [ShiftCheckpoint] {
        return query.apply(store.list())
    }
}

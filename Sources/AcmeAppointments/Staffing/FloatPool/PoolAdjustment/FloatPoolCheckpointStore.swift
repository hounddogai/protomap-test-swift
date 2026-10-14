import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool checkpoints by code.
    protocol FloatPoolCheckpointStore {
        func find(_ code: String) -> FloatPoolCheckpoint?
        func save(_ item: FloatPoolCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolCheckpointStore: FloatPoolCheckpointStore {
        var items: [String: FloatPoolCheckpoint]
        var order: [String]

        init(items: [String: FloatPoolCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolCheckpoint) {
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

        func list() -> [FloatPoolCheckpoint] {
            var out: [FloatPoolCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolCheckpointStore() -> any FloatPoolCheckpointStore {
        return MemoryFloatPoolCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolCheckpointStore: FloatPoolCheckpointStore {
        var inner: MemoryFloatPoolCheckpointStore
        var cache: TTLCache<FloatPoolCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolCheckpointStore, cache: TTLCache<FloatPoolCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolCheckpoint? {
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

        func save(_ item: FloatPoolCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolCheckpointStore(_ inner: MemoryFloatPoolCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolCheckpointStore {
        return CachedFloatPoolCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool checkpoints. Empty fields match all.
    final class FloatPoolCheckpointQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolCheckpoint) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolCheckpoint]) -> [FloatPoolCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolCheckpoints(_ store: any FloatPoolCheckpointStore, query: FloatPoolCheckpointQuery) -> [FloatPoolCheckpoint] {
        return query.apply(store.list())
    }
}

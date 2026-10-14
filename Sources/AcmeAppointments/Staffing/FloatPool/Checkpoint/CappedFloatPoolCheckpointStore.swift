import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped float pool checkpoints by code.
    protocol CappedFloatPoolCheckpointStore {
        func find(_ code: String) -> CappedFloatPoolCheckpoint?
        func save(_ item: CappedFloatPoolCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFloatPoolCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFloatPoolCheckpointStore: CappedFloatPoolCheckpointStore {
        var items: [String: CappedFloatPoolCheckpoint]
        var order: [String]

        init(items: [String: CappedFloatPoolCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFloatPoolCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFloatPoolCheckpoint) {
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

        func list() -> [CappedFloatPoolCheckpoint] {
            var out: [CappedFloatPoolCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFloatPoolCheckpointStore() -> any CappedFloatPoolCheckpointStore {
        return MemoryCappedFloatPoolCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFloatPoolCheckpointStore: CappedFloatPoolCheckpointStore {
        var inner: MemoryCappedFloatPoolCheckpointStore
        var cache: TTLCache<CappedFloatPoolCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFloatPoolCheckpointStore, cache: TTLCache<CappedFloatPoolCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFloatPoolCheckpoint? {
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

        func save(_ item: CappedFloatPoolCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFloatPoolCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedFloatPoolCheckpointStore(_ inner: MemoryCappedFloatPoolCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFloatPoolCheckpointStore {
        return CachedCappedFloatPoolCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped float pool checkpoints. Empty fields match all.
    final class CappedFloatPoolCheckpointQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFloatPoolCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedFloatPoolCheckpoint]) -> [CappedFloatPoolCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFloatPoolCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFloatPoolCheckpoints(_ store: any CappedFloatPoolCheckpointStore, query: CappedFloatPoolCheckpointQuery) -> [CappedFloatPoolCheckpoint] {
        return query.apply(store.list())
    }
}

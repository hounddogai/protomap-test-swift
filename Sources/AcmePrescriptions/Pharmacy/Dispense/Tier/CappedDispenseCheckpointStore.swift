import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped dispense checkpoints by code.
    protocol CappedDispenseCheckpointStore {
        func find(_ code: String) -> CappedDispenseCheckpoint?
        func save(_ item: CappedDispenseCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDispenseCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDispenseCheckpointStore: CappedDispenseCheckpointStore {
        var items: [String: CappedDispenseCheckpoint]
        var order: [String]

        init(items: [String: CappedDispenseCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDispenseCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDispenseCheckpoint) {
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

        func list() -> [CappedDispenseCheckpoint] {
            var out: [CappedDispenseCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDispenseCheckpointStore() -> any CappedDispenseCheckpointStore {
        return MemoryCappedDispenseCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDispenseCheckpointStore: CappedDispenseCheckpointStore {
        var inner: MemoryCappedDispenseCheckpointStore
        var cache: TTLCache<CappedDispenseCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDispenseCheckpointStore, cache: TTLCache<CappedDispenseCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDispenseCheckpoint? {
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

        func save(_ item: CappedDispenseCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDispenseCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedDispenseCheckpointStore(_ inner: MemoryCappedDispenseCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDispenseCheckpointStore {
        return CachedCappedDispenseCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped dispense checkpoints. Empty fields match all.
    final class CappedDispenseCheckpointQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDispenseCheckpoint) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDispenseCheckpoint]) -> [CappedDispenseCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDispenseCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDispenseCheckpoints(_ store: any CappedDispenseCheckpointStore, query: CappedDispenseCheckpointQuery) -> [CappedDispenseCheckpoint] {
        return query.apply(store.list())
    }
}

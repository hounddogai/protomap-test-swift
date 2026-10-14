import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default recall checkpoints by code.
    protocol DefaultRecallCheckpointStore {
        func find(_ code: String) -> DefaultRecallCheckpoint?
        func save(_ item: DefaultRecallCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRecallCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRecallCheckpointStore: DefaultRecallCheckpointStore {
        var items: [String: DefaultRecallCheckpoint]
        var order: [String]

        init(items: [String: DefaultRecallCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRecallCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRecallCheckpoint) {
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

        func list() -> [DefaultRecallCheckpoint] {
            var out: [DefaultRecallCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRecallCheckpointStore() -> any DefaultRecallCheckpointStore {
        return MemoryDefaultRecallCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRecallCheckpointStore: DefaultRecallCheckpointStore {
        var inner: MemoryDefaultRecallCheckpointStore
        var cache: TTLCache<DefaultRecallCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRecallCheckpointStore, cache: TTLCache<DefaultRecallCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRecallCheckpoint? {
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

        func save(_ item: DefaultRecallCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRecallCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDefaultRecallCheckpointStore(_ inner: MemoryDefaultRecallCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRecallCheckpointStore {
        return CachedDefaultRecallCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default recall checkpoints. Empty fields match all.
    final class DefaultRecallCheckpointQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRecallCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [DefaultRecallCheckpoint]) -> [DefaultRecallCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRecallCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRecallCheckpoints(_ store: any DefaultRecallCheckpointStore, query: DefaultRecallCheckpointQuery) -> [DefaultRecallCheckpoint] {
        return query.apply(store.list())
    }
}

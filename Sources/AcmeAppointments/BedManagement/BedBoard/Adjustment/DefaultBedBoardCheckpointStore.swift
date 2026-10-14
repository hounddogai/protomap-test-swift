import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default bed board checkpoints by code.
    protocol DefaultBedBoardCheckpointStore {
        func find(_ code: String) -> DefaultBedBoardCheckpoint?
        func save(_ item: DefaultBedBoardCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultBedBoardCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultBedBoardCheckpointStore: DefaultBedBoardCheckpointStore {
        var items: [String: DefaultBedBoardCheckpoint]
        var order: [String]

        init(items: [String: DefaultBedBoardCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultBedBoardCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultBedBoardCheckpoint) {
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

        func list() -> [DefaultBedBoardCheckpoint] {
            var out: [DefaultBedBoardCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultBedBoardCheckpointStore() -> any DefaultBedBoardCheckpointStore {
        return MemoryDefaultBedBoardCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultBedBoardCheckpointStore: DefaultBedBoardCheckpointStore {
        var inner: MemoryDefaultBedBoardCheckpointStore
        var cache: TTLCache<DefaultBedBoardCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultBedBoardCheckpointStore, cache: TTLCache<DefaultBedBoardCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultBedBoardCheckpoint? {
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

        func save(_ item: DefaultBedBoardCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultBedBoardCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDefaultBedBoardCheckpointStore(_ inner: MemoryDefaultBedBoardCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultBedBoardCheckpointStore {
        return CachedDefaultBedBoardCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default bed board checkpoints. Empty fields match all.
    final class DefaultBedBoardCheckpointQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultBedBoardCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultBedBoardCheckpoint]) -> [DefaultBedBoardCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultBedBoardCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultBedBoardCheckpoints(_ store: any DefaultBedBoardCheckpointStore, query: DefaultBedBoardCheckpointQuery) -> [DefaultBedBoardCheckpoint] {
        return query.apply(store.list())
    }
}

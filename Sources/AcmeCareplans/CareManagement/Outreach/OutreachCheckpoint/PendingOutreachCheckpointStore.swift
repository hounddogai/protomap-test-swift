import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending outreach checkpoints by code.
    protocol PendingOutreachCheckpointStore {
        func find(_ code: String) -> PendingOutreachCheckpoint?
        func save(_ item: PendingOutreachCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOutreachCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOutreachCheckpointStore: PendingOutreachCheckpointStore {
        var items: [String: PendingOutreachCheckpoint]
        var order: [String]

        init(items: [String: PendingOutreachCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOutreachCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOutreachCheckpoint) {
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

        func list() -> [PendingOutreachCheckpoint] {
            var out: [PendingOutreachCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOutreachCheckpointStore() -> any PendingOutreachCheckpointStore {
        return MemoryPendingOutreachCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOutreachCheckpointStore: PendingOutreachCheckpointStore {
        var inner: MemoryPendingOutreachCheckpointStore
        var cache: TTLCache<PendingOutreachCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOutreachCheckpointStore, cache: TTLCache<PendingOutreachCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOutreachCheckpoint? {
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

        func save(_ item: PendingOutreachCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOutreachCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPendingOutreachCheckpointStore(_ inner: MemoryPendingOutreachCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOutreachCheckpointStore {
        return CachedPendingOutreachCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending outreach checkpoints. Empty fields match all.
    final class PendingOutreachCheckpointQuery {
        var category: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOutreachCheckpoint) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PendingOutreachCheckpoint]) -> [PendingOutreachCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOutreachCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOutreachCheckpoints(_ store: any PendingOutreachCheckpointStore, query: PendingOutreachCheckpointQuery) -> [PendingOutreachCheckpoint] {
        return query.apply(store.list())
    }
}

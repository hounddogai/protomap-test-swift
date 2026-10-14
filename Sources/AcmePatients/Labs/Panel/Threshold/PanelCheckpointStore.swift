import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel checkpoints by code.
    protocol PanelCheckpointStore {
        func find(_ code: String) -> PanelCheckpoint?
        func save(_ item: PanelCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PanelCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelCheckpointStore: PanelCheckpointStore {
        var items: [String: PanelCheckpoint]
        var order: [String]

        init(items: [String: PanelCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelCheckpoint) {
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

        func list() -> [PanelCheckpoint] {
            var out: [PanelCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelCheckpointStore() -> any PanelCheckpointStore {
        return MemoryPanelCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelCheckpointStore: PanelCheckpointStore {
        var inner: MemoryPanelCheckpointStore
        var cache: TTLCache<PanelCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelCheckpointStore, cache: TTLCache<PanelCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelCheckpoint? {
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

        func save(_ item: PanelCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPanelCheckpointStore(_ inner: MemoryPanelCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelCheckpointStore {
        return CachedPanelCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel checkpoints. Empty fields match all.
    final class PanelCheckpointQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PanelCheckpoint]) -> [PanelCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelCheckpoints(_ store: any PanelCheckpointStore, query: PanelCheckpointQuery) -> [PanelCheckpoint] {
        return query.apply(store.list())
    }
}

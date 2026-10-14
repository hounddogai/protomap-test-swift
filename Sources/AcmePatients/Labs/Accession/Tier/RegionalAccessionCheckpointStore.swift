import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional accession checkpoints by code.
    protocol RegionalAccessionCheckpointStore {
        func find(_ code: String) -> RegionalAccessionCheckpoint?
        func save(_ item: RegionalAccessionCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAccessionCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAccessionCheckpointStore: RegionalAccessionCheckpointStore {
        var items: [String: RegionalAccessionCheckpoint]
        var order: [String]

        init(items: [String: RegionalAccessionCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAccessionCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAccessionCheckpoint) {
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

        func list() -> [RegionalAccessionCheckpoint] {
            var out: [RegionalAccessionCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAccessionCheckpointStore() -> any RegionalAccessionCheckpointStore {
        return MemoryRegionalAccessionCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAccessionCheckpointStore: RegionalAccessionCheckpointStore {
        var inner: MemoryRegionalAccessionCheckpointStore
        var cache: TTLCache<RegionalAccessionCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAccessionCheckpointStore, cache: TTLCache<RegionalAccessionCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAccessionCheckpoint? {
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

        func save(_ item: RegionalAccessionCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAccessionCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRegionalAccessionCheckpointStore(_ inner: MemoryRegionalAccessionCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAccessionCheckpointStore {
        return CachedRegionalAccessionCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional accession checkpoints. Empty fields match all.
    final class RegionalAccessionCheckpointQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAccessionCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalAccessionCheckpoint]) -> [RegionalAccessionCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAccessionCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAccessionCheckpoints(_ store: any RegionalAccessionCheckpointStore, query: RegionalAccessionCheckpointQuery) -> [RegionalAccessionCheckpoint] {
        return query.apply(store.list())
    }
}

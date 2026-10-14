import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional outreach checkpoints by code.
    protocol RegionalOutreachCheckpointStore {
        func find(_ code: String) -> RegionalOutreachCheckpoint?
        func save(_ item: RegionalOutreachCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalOutreachCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalOutreachCheckpointStore: RegionalOutreachCheckpointStore {
        var items: [String: RegionalOutreachCheckpoint]
        var order: [String]

        init(items: [String: RegionalOutreachCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalOutreachCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalOutreachCheckpoint) {
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

        func list() -> [RegionalOutreachCheckpoint] {
            var out: [RegionalOutreachCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalOutreachCheckpointStore() -> any RegionalOutreachCheckpointStore {
        return MemoryRegionalOutreachCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalOutreachCheckpointStore: RegionalOutreachCheckpointStore {
        var inner: MemoryRegionalOutreachCheckpointStore
        var cache: TTLCache<RegionalOutreachCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalOutreachCheckpointStore, cache: TTLCache<RegionalOutreachCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalOutreachCheckpoint? {
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

        func save(_ item: RegionalOutreachCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalOutreachCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRegionalOutreachCheckpointStore(_ inner: MemoryRegionalOutreachCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalOutreachCheckpointStore {
        return CachedRegionalOutreachCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional outreach checkpoints. Empty fields match all.
    final class RegionalOutreachCheckpointQuery {
        var segment: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minLimit: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalOutreachCheckpoint) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalOutreachCheckpoint]) -> [RegionalOutreachCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalOutreachCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalOutreachCheckpoints(_ store: any RegionalOutreachCheckpointStore, query: RegionalOutreachCheckpointQuery) -> [RegionalOutreachCheckpoint] {
        return query.apply(store.list())
    }
}

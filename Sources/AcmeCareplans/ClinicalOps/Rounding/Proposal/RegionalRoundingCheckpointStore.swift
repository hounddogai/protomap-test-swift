import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional rounding checkpoints by code.
    protocol RegionalRoundingCheckpointStore {
        func find(_ code: String) -> RegionalRoundingCheckpoint?
        func save(_ item: RegionalRoundingCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRoundingCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRoundingCheckpointStore: RegionalRoundingCheckpointStore {
        var items: [String: RegionalRoundingCheckpoint]
        var order: [String]

        init(items: [String: RegionalRoundingCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRoundingCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRoundingCheckpoint) {
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

        func list() -> [RegionalRoundingCheckpoint] {
            var out: [RegionalRoundingCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRoundingCheckpointStore() -> any RegionalRoundingCheckpointStore {
        return MemoryRegionalRoundingCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRoundingCheckpointStore: RegionalRoundingCheckpointStore {
        var inner: MemoryRegionalRoundingCheckpointStore
        var cache: TTLCache<RegionalRoundingCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRoundingCheckpointStore, cache: TTLCache<RegionalRoundingCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRoundingCheckpoint? {
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

        func save(_ item: RegionalRoundingCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRoundingCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedRegionalRoundingCheckpointStore(_ inner: MemoryRegionalRoundingCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRoundingCheckpointStore {
        return CachedRegionalRoundingCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional rounding checkpoints. Empty fields match all.
    final class RegionalRoundingCheckpointQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRoundingCheckpoint) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalRoundingCheckpoint]) -> [RegionalRoundingCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRoundingCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRoundingCheckpoints(_ store: any RegionalRoundingCheckpointStore, query: RegionalRoundingCheckpointQuery) -> [RegionalRoundingCheckpoint] {
        return query.apply(store.list())
    }
}

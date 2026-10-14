import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps seasonal closure checkpoints by code.
    protocol SeasonalClosureCheckpointStore {
        func find(_ code: String) -> SeasonalClosureCheckpoint?
        func save(_ item: SeasonalClosureCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalClosureCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalClosureCheckpointStore: SeasonalClosureCheckpointStore {
        var items: [String: SeasonalClosureCheckpoint]
        var order: [String]

        init(items: [String: SeasonalClosureCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalClosureCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalClosureCheckpoint) {
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

        func list() -> [SeasonalClosureCheckpoint] {
            var out: [SeasonalClosureCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalClosureCheckpointStore() -> any SeasonalClosureCheckpointStore {
        return MemorySeasonalClosureCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalClosureCheckpointStore: SeasonalClosureCheckpointStore {
        var inner: MemorySeasonalClosureCheckpointStore
        var cache: TTLCache<SeasonalClosureCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalClosureCheckpointStore, cache: TTLCache<SeasonalClosureCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalClosureCheckpoint? {
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

        func save(_ item: SeasonalClosureCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalClosureCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedSeasonalClosureCheckpointStore(_ inner: MemorySeasonalClosureCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalClosureCheckpointStore {
        return CachedSeasonalClosureCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal closure checkpoints. Empty fields match all.
    final class SeasonalClosureCheckpointQuery {
        var channel: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalClosureCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalClosureCheckpoint]) -> [SeasonalClosureCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalClosureCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalClosureCheckpoints(_ store: any SeasonalClosureCheckpointStore, query: SeasonalClosureCheckpointQuery) -> [SeasonalClosureCheckpoint] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal language checkpoints by code.
    protocol SeasonalLanguageCheckpointStore {
        func find(_ code: String) -> SeasonalLanguageCheckpoint?
        func save(_ item: SeasonalLanguageCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalLanguageCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalLanguageCheckpointStore: SeasonalLanguageCheckpointStore {
        var items: [String: SeasonalLanguageCheckpoint]
        var order: [String]

        init(items: [String: SeasonalLanguageCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalLanguageCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalLanguageCheckpoint) {
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

        func list() -> [SeasonalLanguageCheckpoint] {
            var out: [SeasonalLanguageCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalLanguageCheckpointStore() -> any SeasonalLanguageCheckpointStore {
        return MemorySeasonalLanguageCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalLanguageCheckpointStore: SeasonalLanguageCheckpointStore {
        var inner: MemorySeasonalLanguageCheckpointStore
        var cache: TTLCache<SeasonalLanguageCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalLanguageCheckpointStore, cache: TTLCache<SeasonalLanguageCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalLanguageCheckpoint? {
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

        func save(_ item: SeasonalLanguageCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalLanguageCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedSeasonalLanguageCheckpointStore(_ inner: MemorySeasonalLanguageCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalLanguageCheckpointStore {
        return CachedSeasonalLanguageCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal language checkpoints. Empty fields match all.
    final class SeasonalLanguageCheckpointQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalLanguageCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SeasonalLanguageCheckpoint]) -> [SeasonalLanguageCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalLanguageCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalLanguageCheckpoints(_ store: any SeasonalLanguageCheckpointStore, query: SeasonalLanguageCheckpointQuery) -> [SeasonalLanguageCheckpoint] {
        return query.apply(store.list())
    }
}

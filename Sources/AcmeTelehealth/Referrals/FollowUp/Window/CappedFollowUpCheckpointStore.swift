import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped follow up checkpoints by code.
    protocol CappedFollowUpCheckpointStore {
        func find(_ code: String) -> CappedFollowUpCheckpoint?
        func save(_ item: CappedFollowUpCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedFollowUpCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedFollowUpCheckpointStore: CappedFollowUpCheckpointStore {
        var items: [String: CappedFollowUpCheckpoint]
        var order: [String]

        init(items: [String: CappedFollowUpCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedFollowUpCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedFollowUpCheckpoint) {
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

        func list() -> [CappedFollowUpCheckpoint] {
            var out: [CappedFollowUpCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedFollowUpCheckpointStore() -> any CappedFollowUpCheckpointStore {
        return MemoryCappedFollowUpCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedFollowUpCheckpointStore: CappedFollowUpCheckpointStore {
        var inner: MemoryCappedFollowUpCheckpointStore
        var cache: TTLCache<CappedFollowUpCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedFollowUpCheckpointStore, cache: TTLCache<CappedFollowUpCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedFollowUpCheckpoint? {
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

        func save(_ item: CappedFollowUpCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedFollowUpCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedFollowUpCheckpointStore(_ inner: MemoryCappedFollowUpCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedFollowUpCheckpointStore {
        return CachedCappedFollowUpCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped follow up checkpoints. Empty fields match all.
    final class CappedFollowUpCheckpointQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedFollowUpCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [CappedFollowUpCheckpoint]) -> [CappedFollowUpCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedFollowUpCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedFollowUpCheckpoints(_ store: any CappedFollowUpCheckpointStore, query: CappedFollowUpCheckpointQuery) -> [CappedFollowUpCheckpoint] {
        return query.apply(store.list())
    }
}

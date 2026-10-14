import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up checkpoints by code.
    protocol FollowUpCheckpointStore {
        func find(_ code: String) -> FollowUpCheckpoint?
        func save(_ item: FollowUpCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpCheckpointStore: FollowUpCheckpointStore {
        var items: [String: FollowUpCheckpoint]
        var order: [String]

        init(items: [String: FollowUpCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpCheckpoint) {
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

        func list() -> [FollowUpCheckpoint] {
            var out: [FollowUpCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpCheckpointStore() -> any FollowUpCheckpointStore {
        return MemoryFollowUpCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpCheckpointStore: FollowUpCheckpointStore {
        var inner: MemoryFollowUpCheckpointStore
        var cache: TTLCache<FollowUpCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpCheckpointStore, cache: TTLCache<FollowUpCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpCheckpoint? {
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

        func save(_ item: FollowUpCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedFollowUpCheckpointStore(_ inner: MemoryFollowUpCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpCheckpointStore {
        return CachedFollowUpCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up checkpoints. Empty fields match all.
    final class FollowUpCheckpointQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpCheckpoint]) -> [FollowUpCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpCheckpoints(_ store: any FollowUpCheckpointStore, query: FollowUpCheckpointQuery) -> [FollowUpCheckpoint] {
        return query.apply(store.list())
    }
}

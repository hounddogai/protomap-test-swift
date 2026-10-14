import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped eligibility checkpoints by code.
    protocol CappedEligibilityCheckpointStore {
        func find(_ code: String) -> CappedEligibilityCheckpoint?
        func save(_ item: CappedEligibilityCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CappedEligibilityCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedEligibilityCheckpointStore: CappedEligibilityCheckpointStore {
        var items: [String: CappedEligibilityCheckpoint]
        var order: [String]

        init(items: [String: CappedEligibilityCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedEligibilityCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedEligibilityCheckpoint) {
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

        func list() -> [CappedEligibilityCheckpoint] {
            var out: [CappedEligibilityCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedEligibilityCheckpointStore() -> any CappedEligibilityCheckpointStore {
        return MemoryCappedEligibilityCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedEligibilityCheckpointStore: CappedEligibilityCheckpointStore {
        var inner: MemoryCappedEligibilityCheckpointStore
        var cache: TTLCache<CappedEligibilityCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedEligibilityCheckpointStore, cache: TTLCache<CappedEligibilityCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedEligibilityCheckpoint? {
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

        func save(_ item: CappedEligibilityCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedEligibilityCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCappedEligibilityCheckpointStore(_ inner: MemoryCappedEligibilityCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedEligibilityCheckpointStore {
        return CachedCappedEligibilityCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped eligibility checkpoints. Empty fields match all.
    final class CappedEligibilityCheckpointQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedEligibilityCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedEligibilityCheckpoint]) -> [CappedEligibilityCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedEligibilityCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedEligibilityCheckpoints(_ store: any CappedEligibilityCheckpointStore, query: CappedEligibilityCheckpointQuery) -> [CappedEligibilityCheckpoint] {
        return query.apply(store.list())
    }
}

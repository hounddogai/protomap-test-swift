import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility checkpoints by code.
    protocol EligibilityCheckpointStore {
        func find(_ code: String) -> EligibilityCheckpoint?
        func save(_ item: EligibilityCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityCheckpointStore: EligibilityCheckpointStore {
        var items: [String: EligibilityCheckpoint]
        var order: [String]

        init(items: [String: EligibilityCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityCheckpoint) {
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

        func list() -> [EligibilityCheckpoint] {
            var out: [EligibilityCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityCheckpointStore() -> any EligibilityCheckpointStore {
        return MemoryEligibilityCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityCheckpointStore: EligibilityCheckpointStore {
        var inner: MemoryEligibilityCheckpointStore
        var cache: TTLCache<EligibilityCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityCheckpointStore, cache: TTLCache<EligibilityCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityCheckpoint? {
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

        func save(_ item: EligibilityCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedEligibilityCheckpointStore(_ inner: MemoryEligibilityCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityCheckpointStore {
        return CachedEligibilityCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility checkpoints. Empty fields match all.
    final class EligibilityCheckpointQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityCheckpoint]) -> [EligibilityCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityCheckpoints(_ store: any EligibilityCheckpointStore, query: EligibilityCheckpointQuery) -> [EligibilityCheckpoint] {
        return query.apply(store.list())
    }
}

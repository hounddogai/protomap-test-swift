import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial checkpoints by code.
    protocol DenialCheckpointStore {
        func find(_ code: String) -> DenialCheckpoint?
        func save(_ item: DenialCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DenialCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialCheckpointStore: DenialCheckpointStore {
        var items: [String: DenialCheckpoint]
        var order: [String]

        init(items: [String: DenialCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialCheckpoint) {
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

        func list() -> [DenialCheckpoint] {
            var out: [DenialCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialCheckpointStore() -> any DenialCheckpointStore {
        return MemoryDenialCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialCheckpointStore: DenialCheckpointStore {
        var inner: MemoryDenialCheckpointStore
        var cache: TTLCache<DenialCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialCheckpointStore, cache: TTLCache<DenialCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialCheckpoint? {
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

        func save(_ item: DenialCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDenialCheckpointStore(_ inner: MemoryDenialCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialCheckpointStore {
        return CachedDenialCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial checkpoints. Empty fields match all.
    final class DenialCheckpointQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialCheckpoint]) -> [DenialCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialCheckpoints(_ store: any DenialCheckpointStore, query: DenialCheckpointQuery) -> [DenialCheckpoint] {
        return query.apply(store.list())
    }
}

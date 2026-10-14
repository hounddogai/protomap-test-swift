import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict claim checkpoints by code.
    protocol StrictClaimCheckpointStore {
        func find(_ code: String) -> StrictClaimCheckpoint?
        func save(_ item: StrictClaimCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [StrictClaimCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictClaimCheckpointStore: StrictClaimCheckpointStore {
        var items: [String: StrictClaimCheckpoint]
        var order: [String]

        init(items: [String: StrictClaimCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictClaimCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictClaimCheckpoint) {
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

        func list() -> [StrictClaimCheckpoint] {
            var out: [StrictClaimCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictClaimCheckpointStore() -> any StrictClaimCheckpointStore {
        return MemoryStrictClaimCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictClaimCheckpointStore: StrictClaimCheckpointStore {
        var inner: MemoryStrictClaimCheckpointStore
        var cache: TTLCache<StrictClaimCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictClaimCheckpointStore, cache: TTLCache<StrictClaimCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictClaimCheckpoint? {
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

        func save(_ item: StrictClaimCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictClaimCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedStrictClaimCheckpointStore(_ inner: MemoryStrictClaimCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictClaimCheckpointStore {
        return CachedStrictClaimCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict claim checkpoints. Empty fields match all.
    final class StrictClaimCheckpointQuery {
        var locale: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minPriority: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictClaimCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [StrictClaimCheckpoint]) -> [StrictClaimCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictClaimCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictClaimCheckpoints(_ store: any StrictClaimCheckpointStore, query: StrictClaimCheckpointQuery) -> [StrictClaimCheckpoint] {
        return query.apply(store.list())
    }
}

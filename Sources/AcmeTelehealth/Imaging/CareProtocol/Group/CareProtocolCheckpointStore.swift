import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol checkpoints by code.
    protocol CareProtocolCheckpointStore {
        func find(_ code: String) -> CareProtocolCheckpoint?
        func save(_ item: CareProtocolCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolCheckpointStore: CareProtocolCheckpointStore {
        var items: [String: CareProtocolCheckpoint]
        var order: [String]

        init(items: [String: CareProtocolCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolCheckpoint) {
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

        func list() -> [CareProtocolCheckpoint] {
            var out: [CareProtocolCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolCheckpointStore() -> any CareProtocolCheckpointStore {
        return MemoryCareProtocolCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolCheckpointStore: CareProtocolCheckpointStore {
        var inner: MemoryCareProtocolCheckpointStore
        var cache: TTLCache<CareProtocolCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolCheckpointStore, cache: TTLCache<CareProtocolCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolCheckpoint? {
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

        func save(_ item: CareProtocolCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolCheckpointStore(_ inner: MemoryCareProtocolCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolCheckpointStore {
        return CachedCareProtocolCheckpointStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol checkpoints. Empty fields match all.
    final class CareProtocolCheckpointQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolCheckpoint) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolCheckpoint]) -> [CareProtocolCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolCheckpoints(_ store: any CareProtocolCheckpointStore, query: CareProtocolCheckpointQuery) -> [CareProtocolCheckpoint] {
        return query.apply(store.list())
    }
}

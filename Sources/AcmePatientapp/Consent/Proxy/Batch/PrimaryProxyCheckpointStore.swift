import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary proxy checkpoints by code.
    protocol PrimaryProxyCheckpointStore {
        func find(_ code: String) -> PrimaryProxyCheckpoint?
        func save(_ item: PrimaryProxyCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryProxyCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryProxyCheckpointStore: PrimaryProxyCheckpointStore {
        var items: [String: PrimaryProxyCheckpoint]
        var order: [String]

        init(items: [String: PrimaryProxyCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryProxyCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryProxyCheckpoint) {
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

        func list() -> [PrimaryProxyCheckpoint] {
            var out: [PrimaryProxyCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryProxyCheckpointStore() -> any PrimaryProxyCheckpointStore {
        return MemoryPrimaryProxyCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryProxyCheckpointStore: PrimaryProxyCheckpointStore {
        var inner: MemoryPrimaryProxyCheckpointStore
        var cache: TTLCache<PrimaryProxyCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryProxyCheckpointStore, cache: TTLCache<PrimaryProxyCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryProxyCheckpoint? {
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

        func save(_ item: PrimaryProxyCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryProxyCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedPrimaryProxyCheckpointStore(_ inner: MemoryPrimaryProxyCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryProxyCheckpointStore {
        return CachedPrimaryProxyCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary proxy checkpoints. Empty fields match all.
    final class PrimaryProxyCheckpointQuery {
        var country: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCopay: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryProxyCheckpoint) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [PrimaryProxyCheckpoint]) -> [PrimaryProxyCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryProxyCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryProxyCheckpoints(_ store: any PrimaryProxyCheckpointStore, query: PrimaryProxyCheckpointQuery) -> [PrimaryProxyCheckpoint] {
        return query.apply(store.list())
    }
}

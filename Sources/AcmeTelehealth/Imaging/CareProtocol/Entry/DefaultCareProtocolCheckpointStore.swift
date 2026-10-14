import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps default care protocol checkpoints by code.
    protocol DefaultCareProtocolCheckpointStore {
        func find(_ code: String) -> DefaultCareProtocolCheckpoint?
        func save(_ item: DefaultCareProtocolCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolCheckpointStore: DefaultCareProtocolCheckpointStore {
        var items: [String: DefaultCareProtocolCheckpoint]
        var order: [String]

        init(items: [String: DefaultCareProtocolCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolCheckpoint) {
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

        func list() -> [DefaultCareProtocolCheckpoint] {
            var out: [DefaultCareProtocolCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolCheckpointStore() -> any DefaultCareProtocolCheckpointStore {
        return MemoryDefaultCareProtocolCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolCheckpointStore: DefaultCareProtocolCheckpointStore {
        var inner: MemoryDefaultCareProtocolCheckpointStore
        var cache: TTLCache<DefaultCareProtocolCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolCheckpointStore, cache: TTLCache<DefaultCareProtocolCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolCheckpoint? {
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

        func save(_ item: DefaultCareProtocolCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolCheckpointStore(_ inner: MemoryDefaultCareProtocolCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolCheckpointStore {
        return CachedDefaultCareProtocolCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol checkpoints. Empty fields match all.
    final class DefaultCareProtocolCheckpointQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolCheckpoint) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultCareProtocolCheckpoint]) -> [DefaultCareProtocolCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolCheckpoints(_ store: any DefaultCareProtocolCheckpointStore, query: DefaultCareProtocolCheckpointQuery) -> [DefaultCareProtocolCheckpoint] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert checkpoints by code.
    protocol AlertCheckpointStore {
        func find(_ code: String) -> AlertCheckpoint?
        func save(_ item: AlertCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [AlertCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertCheckpointStore: AlertCheckpointStore {
        var items: [String: AlertCheckpoint]
        var order: [String]

        init(items: [String: AlertCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertCheckpoint) {
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

        func list() -> [AlertCheckpoint] {
            var out: [AlertCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertCheckpointStore() -> any AlertCheckpointStore {
        return MemoryAlertCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertCheckpointStore: AlertCheckpointStore {
        var inner: MemoryAlertCheckpointStore
        var cache: TTLCache<AlertCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertCheckpointStore, cache: TTLCache<AlertCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertCheckpoint? {
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

        func save(_ item: AlertCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedAlertCheckpointStore(_ inner: MemoryAlertCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertCheckpointStore {
        return CachedAlertCheckpointStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert checkpoints. Empty fields match all.
    final class AlertCheckpointQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertCheckpoint) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertCheckpoint]) -> [AlertCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertCheckpoints(_ store: any AlertCheckpointStore, query: AlertCheckpointQuery) -> [AlertCheckpoint] {
        return query.apply(store.list())
    }
}

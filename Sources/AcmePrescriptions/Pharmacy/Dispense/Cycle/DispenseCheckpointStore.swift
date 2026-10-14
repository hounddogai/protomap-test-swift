import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense checkpoints by code.
    protocol DispenseCheckpointStore {
        func find(_ code: String) -> DispenseCheckpoint?
        func save(_ item: DispenseCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseCheckpointStore: DispenseCheckpointStore {
        var items: [String: DispenseCheckpoint]
        var order: [String]

        init(items: [String: DispenseCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseCheckpoint) {
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

        func list() -> [DispenseCheckpoint] {
            var out: [DispenseCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseCheckpointStore() -> any DispenseCheckpointStore {
        return MemoryDispenseCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseCheckpointStore: DispenseCheckpointStore {
        var inner: MemoryDispenseCheckpointStore
        var cache: TTLCache<DispenseCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseCheckpointStore, cache: TTLCache<DispenseCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseCheckpoint? {
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

        func save(_ item: DispenseCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedDispenseCheckpointStore(_ inner: MemoryDispenseCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseCheckpointStore {
        return CachedDispenseCheckpointStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense checkpoints. Empty fields match all.
    final class DispenseCheckpointQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseCheckpoint]) -> [DispenseCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseCheckpoints(_ store: any DispenseCheckpointStore, query: DispenseCheckpointQuery) -> [DispenseCheckpoint] {
        return query.apply(store.list())
    }
}

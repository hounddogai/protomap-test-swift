import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict slot checkpoints by code.
    protocol StrictSlotCheckpointStore {
        func find(_ code: String) -> StrictSlotCheckpoint?
        func save(_ item: StrictSlotCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSlotCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSlotCheckpointStore: StrictSlotCheckpointStore {
        var items: [String: StrictSlotCheckpoint]
        var order: [String]

        init(items: [String: StrictSlotCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSlotCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSlotCheckpoint) {
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

        func list() -> [StrictSlotCheckpoint] {
            var out: [StrictSlotCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSlotCheckpointStore() -> any StrictSlotCheckpointStore {
        return MemoryStrictSlotCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSlotCheckpointStore: StrictSlotCheckpointStore {
        var inner: MemoryStrictSlotCheckpointStore
        var cache: TTLCache<StrictSlotCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSlotCheckpointStore, cache: TTLCache<StrictSlotCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSlotCheckpoint? {
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

        func save(_ item: StrictSlotCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSlotCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedStrictSlotCheckpointStore(_ inner: MemoryStrictSlotCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSlotCheckpointStore {
        return CachedStrictSlotCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict slot checkpoints. Empty fields match all.
    final class StrictSlotCheckpointQuery {
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

        func matches(_ item: StrictSlotCheckpoint) -> Bool {
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

        func apply(_ items: [StrictSlotCheckpoint]) -> [StrictSlotCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSlotCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSlotCheckpoints(_ store: any StrictSlotCheckpointStore, query: StrictSlotCheckpointQuery) -> [StrictSlotCheckpoint] {
        return query.apply(store.list())
    }
}

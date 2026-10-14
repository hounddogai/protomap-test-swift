import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global reference range checkpoints by code.
    protocol GlobalReferenceRangeCheckpointStore {
        func find(_ code: String) -> GlobalReferenceRangeCheckpoint?
        func save(_ item: GlobalReferenceRangeCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalReferenceRangeCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalReferenceRangeCheckpointStore: GlobalReferenceRangeCheckpointStore {
        var items: [String: GlobalReferenceRangeCheckpoint]
        var order: [String]

        init(items: [String: GlobalReferenceRangeCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalReferenceRangeCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalReferenceRangeCheckpoint) {
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

        func list() -> [GlobalReferenceRangeCheckpoint] {
            var out: [GlobalReferenceRangeCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalReferenceRangeCheckpointStore() -> any GlobalReferenceRangeCheckpointStore {
        return MemoryGlobalReferenceRangeCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalReferenceRangeCheckpointStore: GlobalReferenceRangeCheckpointStore {
        var inner: MemoryGlobalReferenceRangeCheckpointStore
        var cache: TTLCache<GlobalReferenceRangeCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalReferenceRangeCheckpointStore, cache: TTLCache<GlobalReferenceRangeCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalReferenceRangeCheckpoint? {
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

        func save(_ item: GlobalReferenceRangeCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalReferenceRangeCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedGlobalReferenceRangeCheckpointStore(_ inner: MemoryGlobalReferenceRangeCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalReferenceRangeCheckpointStore {
        return CachedGlobalReferenceRangeCheckpointStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global reference range checkpoints. Empty fields match all.
    final class GlobalReferenceRangeCheckpointQuery {
        var locale: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minWeight: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalReferenceRangeCheckpoint) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalReferenceRangeCheckpoint]) -> [GlobalReferenceRangeCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalReferenceRangeCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalReferenceRangeCheckpoints(_ store: any GlobalReferenceRangeCheckpointStore, query: GlobalReferenceRangeCheckpointQuery) -> [GlobalReferenceRangeCheckpoint] {
        return query.apply(store.list())
    }
}

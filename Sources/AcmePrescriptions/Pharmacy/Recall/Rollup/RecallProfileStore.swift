import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall profiles by code.
    protocol RecallProfileStore {
        func find(_ code: String) -> RecallProfile?
        func save(_ item: RecallProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RecallProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallProfileStore: RecallProfileStore {
        var items: [String: RecallProfile]
        var order: [String]

        init(items: [String: RecallProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallProfile) {
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

        func list() -> [RecallProfile] {
            var out: [RecallProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallProfileStore() -> any RecallProfileStore {
        return MemoryRecallProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallProfileStore: RecallProfileStore {
        var inner: MemoryRecallProfileStore
        var cache: TTLCache<RecallProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallProfileStore, cache: TTLCache<RecallProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallProfile? {
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

        func save(_ item: RecallProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallProfile] {
            return inner.list()
        }
    }

    static func newCachedRecallProfileStore(_ inner: MemoryRecallProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallProfileStore {
        return CachedRecallProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall profiles. Empty fields match all.
    final class RecallProfileQuery {
        var source: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallProfile) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallProfile]) -> [RecallProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallProfiles(_ store: any RecallProfileStore, query: RecallProfileQuery) -> [RecallProfile] {
        return query.apply(store.list())
    }
}

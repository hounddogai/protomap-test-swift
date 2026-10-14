import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled revocation groups by code.
    protocol ScheduledRevocationGroupStore {
        func find(_ code: String) -> ScheduledRevocationGroup?
        func save(_ item: ScheduledRevocationGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledRevocationGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledRevocationGroupStore: ScheduledRevocationGroupStore {
        var items: [String: ScheduledRevocationGroup]
        var order: [String]

        init(items: [String: ScheduledRevocationGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledRevocationGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledRevocationGroup) {
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

        func list() -> [ScheduledRevocationGroup] {
            var out: [ScheduledRevocationGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledRevocationGroupStore() -> any ScheduledRevocationGroupStore {
        return MemoryScheduledRevocationGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledRevocationGroupStore: ScheduledRevocationGroupStore {
        var inner: MemoryScheduledRevocationGroupStore
        var cache: TTLCache<ScheduledRevocationGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledRevocationGroupStore, cache: TTLCache<ScheduledRevocationGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledRevocationGroup? {
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

        func save(_ item: ScheduledRevocationGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledRevocationGroup] {
            return inner.list()
        }
    }

    static func newCachedScheduledRevocationGroupStore(_ inner: MemoryScheduledRevocationGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledRevocationGroupStore {
        return CachedScheduledRevocationGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled revocation groups. Empty fields match all.
    final class ScheduledRevocationGroupQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledRevocationGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ScheduledRevocationGroup]) -> [ScheduledRevocationGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledRevocationGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledRevocationGroups(_ store: any ScheduledRevocationGroupStore, query: ScheduledRevocationGroupQuery) -> [ScheduledRevocationGroup] {
        return query.apply(store.list())
    }
}

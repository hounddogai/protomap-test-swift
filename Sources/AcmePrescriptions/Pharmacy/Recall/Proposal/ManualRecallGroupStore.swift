import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual recall groups by code.
    protocol ManualRecallGroupStore {
        func find(_ code: String) -> ManualRecallGroup?
        func save(_ item: ManualRecallGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRecallGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRecallGroupStore: ManualRecallGroupStore {
        var items: [String: ManualRecallGroup]
        var order: [String]

        init(items: [String: ManualRecallGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRecallGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRecallGroup) {
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

        func list() -> [ManualRecallGroup] {
            var out: [ManualRecallGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRecallGroupStore() -> any ManualRecallGroupStore {
        return MemoryManualRecallGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRecallGroupStore: ManualRecallGroupStore {
        var inner: MemoryManualRecallGroupStore
        var cache: TTLCache<ManualRecallGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRecallGroupStore, cache: TTLCache<ManualRecallGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRecallGroup? {
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

        func save(_ item: ManualRecallGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRecallGroup] {
            return inner.list()
        }
    }

    static func newCachedManualRecallGroupStore(_ inner: MemoryManualRecallGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRecallGroupStore {
        return CachedManualRecallGroupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual recall groups. Empty fields match all.
    final class ManualRecallGroupQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRecallGroup) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ManualRecallGroup]) -> [ManualRecallGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRecallGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRecallGroups(_ store: any ManualRecallGroupStore, query: ManualRecallGroupQuery) -> [ManualRecallGroup] {
        return query.apply(store.list())
    }
}

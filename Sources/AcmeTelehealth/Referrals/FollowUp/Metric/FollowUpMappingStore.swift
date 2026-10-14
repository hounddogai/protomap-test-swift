import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up mappings by code.
    protocol FollowUpMappingStore {
        func find(_ code: String) -> FollowUpMapping?
        func save(_ item: FollowUpMapping)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpMappingStore: FollowUpMappingStore {
        var items: [String: FollowUpMapping]
        var order: [String]

        init(items: [String: FollowUpMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpMapping) {
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

        func list() -> [FollowUpMapping] {
            var out: [FollowUpMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpMappingStore() -> any FollowUpMappingStore {
        return MemoryFollowUpMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpMappingStore: FollowUpMappingStore {
        var inner: MemoryFollowUpMappingStore
        var cache: TTLCache<FollowUpMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpMappingStore, cache: TTLCache<FollowUpMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpMapping? {
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

        func save(_ item: FollowUpMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpMapping] {
            return inner.list()
        }
    }

    static func newCachedFollowUpMappingStore(_ inner: MemoryFollowUpMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpMappingStore {
        return CachedFollowUpMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up mappings. Empty fields match all.
    final class FollowUpMappingQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FollowUpMapping]) -> [FollowUpMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpMappings(_ store: any FollowUpMappingStore, query: FollowUpMappingQuery) -> [FollowUpMapping] {
        return query.apply(store.list())
    }
}

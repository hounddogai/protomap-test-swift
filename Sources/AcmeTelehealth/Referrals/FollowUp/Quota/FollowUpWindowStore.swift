import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up windows by code.
    protocol FollowUpWindowStore {
        func find(_ code: String) -> FollowUpWindow?
        func save(_ item: FollowUpWindow)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpWindowStore: FollowUpWindowStore {
        var items: [String: FollowUpWindow]
        var order: [String]

        init(items: [String: FollowUpWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpWindow) {
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

        func list() -> [FollowUpWindow] {
            var out: [FollowUpWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpWindowStore() -> any FollowUpWindowStore {
        return MemoryFollowUpWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpWindowStore: FollowUpWindowStore {
        var inner: MemoryFollowUpWindowStore
        var cache: TTLCache<FollowUpWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpWindowStore, cache: TTLCache<FollowUpWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpWindow? {
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

        func save(_ item: FollowUpWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpWindow] {
            return inner.list()
        }
    }

    static func newCachedFollowUpWindowStore(_ inner: MemoryFollowUpWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpWindowStore {
        return CachedFollowUpWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up windows. Empty fields match all.
    final class FollowUpWindowQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpWindow]) -> [FollowUpWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpWindows(_ store: any FollowUpWindowStore, query: FollowUpWindowQuery) -> [FollowUpWindow] {
        return query.apply(store.list())
    }
}

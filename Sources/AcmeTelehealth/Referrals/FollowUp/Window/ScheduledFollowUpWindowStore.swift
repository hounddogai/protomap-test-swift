import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled follow up windows by code.
    protocol ScheduledFollowUpWindowStore {
        func find(_ code: String) -> ScheduledFollowUpWindow?
        func save(_ item: ScheduledFollowUpWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFollowUpWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFollowUpWindowStore: ScheduledFollowUpWindowStore {
        var items: [String: ScheduledFollowUpWindow]
        var order: [String]

        init(items: [String: ScheduledFollowUpWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFollowUpWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFollowUpWindow) {
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

        func list() -> [ScheduledFollowUpWindow] {
            var out: [ScheduledFollowUpWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFollowUpWindowStore() -> any ScheduledFollowUpWindowStore {
        return MemoryScheduledFollowUpWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFollowUpWindowStore: ScheduledFollowUpWindowStore {
        var inner: MemoryScheduledFollowUpWindowStore
        var cache: TTLCache<ScheduledFollowUpWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFollowUpWindowStore, cache: TTLCache<ScheduledFollowUpWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFollowUpWindow? {
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

        func save(_ item: ScheduledFollowUpWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFollowUpWindow] {
            return inner.list()
        }
    }

    static func newCachedScheduledFollowUpWindowStore(_ inner: MemoryScheduledFollowUpWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFollowUpWindowStore {
        return CachedScheduledFollowUpWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled follow up windows. Empty fields match all.
    final class ScheduledFollowUpWindowQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFollowUpWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ScheduledFollowUpWindow]) -> [ScheduledFollowUpWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFollowUpWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFollowUpWindows(_ store: any ScheduledFollowUpWindowStore, query: ScheduledFollowUpWindowQuery) -> [ScheduledFollowUpWindow] {
        return query.apply(store.list())
    }
}

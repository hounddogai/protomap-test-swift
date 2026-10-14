import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled handoff windows by code.
    protocol ScheduledHandoffWindowStore {
        func find(_ code: String) -> ScheduledHandoffWindow?
        func save(_ item: ScheduledHandoffWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledHandoffWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledHandoffWindowStore: ScheduledHandoffWindowStore {
        var items: [String: ScheduledHandoffWindow]
        var order: [String]

        init(items: [String: ScheduledHandoffWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledHandoffWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledHandoffWindow) {
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

        func list() -> [ScheduledHandoffWindow] {
            var out: [ScheduledHandoffWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledHandoffWindowStore() -> any ScheduledHandoffWindowStore {
        return MemoryScheduledHandoffWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledHandoffWindowStore: ScheduledHandoffWindowStore {
        var inner: MemoryScheduledHandoffWindowStore
        var cache: TTLCache<ScheduledHandoffWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledHandoffWindowStore, cache: TTLCache<ScheduledHandoffWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledHandoffWindow? {
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

        func save(_ item: ScheduledHandoffWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledHandoffWindow] {
            return inner.list()
        }
    }

    static func newCachedScheduledHandoffWindowStore(_ inner: MemoryScheduledHandoffWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledHandoffWindowStore {
        return CachedScheduledHandoffWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled handoff windows. Empty fields match all.
    final class ScheduledHandoffWindowQuery {
        var channel: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledHandoffWindow) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledHandoffWindow]) -> [ScheduledHandoffWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledHandoffWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledHandoffWindows(_ store: any ScheduledHandoffWindowStore, query: ScheduledHandoffWindowQuery) -> [ScheduledHandoffWindow] {
        return query.apply(store.list())
    }
}

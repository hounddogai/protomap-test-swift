import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime windows by code.
    protocol OvertimeWindowStore {
        func find(_ code: String) -> OvertimeWindow?
        func save(_ item: OvertimeWindow)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeWindowStore: OvertimeWindowStore {
        var items: [String: OvertimeWindow]
        var order: [String]

        init(items: [String: OvertimeWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeWindow) {
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

        func list() -> [OvertimeWindow] {
            var out: [OvertimeWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeWindowStore() -> any OvertimeWindowStore {
        return MemoryOvertimeWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeWindowStore: OvertimeWindowStore {
        var inner: MemoryOvertimeWindowStore
        var cache: TTLCache<OvertimeWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeWindowStore, cache: TTLCache<OvertimeWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeWindow? {
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

        func save(_ item: OvertimeWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeWindow] {
            return inner.list()
        }
    }

    static func newCachedOvertimeWindowStore(_ inner: MemoryOvertimeWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeWindowStore {
        return CachedOvertimeWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime windows. Empty fields match all.
    final class OvertimeWindowQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeWindow]) -> [OvertimeWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeWindows(_ store: any OvertimeWindowStore, query: OvertimeWindowQuery) -> [OvertimeWindow] {
        return query.apply(store.list())
    }
}

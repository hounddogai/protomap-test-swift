import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach windows by code.
    protocol OutreachWindowStore {
        func find(_ code: String) -> OutreachWindow?
        func save(_ item: OutreachWindow)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachWindowStore: OutreachWindowStore {
        var items: [String: OutreachWindow]
        var order: [String]

        init(items: [String: OutreachWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachWindow) {
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

        func list() -> [OutreachWindow] {
            var out: [OutreachWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachWindowStore() -> any OutreachWindowStore {
        return MemoryOutreachWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachWindowStore: OutreachWindowStore {
        var inner: MemoryOutreachWindowStore
        var cache: TTLCache<OutreachWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachWindowStore, cache: TTLCache<OutreachWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachWindow? {
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

        func save(_ item: OutreachWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachWindow] {
            return inner.list()
        }
    }

    static func newCachedOutreachWindowStore(_ inner: MemoryOutreachWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachWindowStore {
        return CachedOutreachWindowStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach windows. Empty fields match all.
    final class OutreachWindowQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachWindow) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachWindow]) -> [OutreachWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachWindows(_ store: any OutreachWindowStore, query: OutreachWindowQuery) -> [OutreachWindow] {
        return query.apply(store.list())
    }
}

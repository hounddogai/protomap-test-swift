import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan windows by code.
    protocol DischargePlanWindowStore {
        func find(_ code: String) -> DischargePlanWindow?
        func save(_ item: DischargePlanWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanWindowStore: DischargePlanWindowStore {
        var items: [String: DischargePlanWindow]
        var order: [String]

        init(items: [String: DischargePlanWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanWindow) {
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

        func list() -> [DischargePlanWindow] {
            var out: [DischargePlanWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanWindowStore() -> any DischargePlanWindowStore {
        return MemoryDischargePlanWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanWindowStore: DischargePlanWindowStore {
        var inner: MemoryDischargePlanWindowStore
        var cache: TTLCache<DischargePlanWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanWindowStore, cache: TTLCache<DischargePlanWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanWindow? {
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

        func save(_ item: DischargePlanWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanWindow] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanWindowStore(_ inner: MemoryDischargePlanWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanWindowStore {
        return CachedDischargePlanWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan windows. Empty fields match all.
    final class DischargePlanWindowQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanWindow) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanWindow]) -> [DischargePlanWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanWindows(_ store: any DischargePlanWindowStore, query: DischargePlanWindowQuery) -> [DischargePlanWindow] {
        return query.apply(store.list())
    }
}

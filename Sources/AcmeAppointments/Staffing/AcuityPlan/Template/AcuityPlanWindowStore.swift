import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan windows by code.
    protocol AcuityPlanWindowStore {
        func find(_ code: String) -> AcuityPlanWindow?
        func save(_ item: AcuityPlanWindow)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanWindowStore: AcuityPlanWindowStore {
        var items: [String: AcuityPlanWindow]
        var order: [String]

        init(items: [String: AcuityPlanWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanWindow) {
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

        func list() -> [AcuityPlanWindow] {
            var out: [AcuityPlanWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanWindowStore() -> any AcuityPlanWindowStore {
        return MemoryAcuityPlanWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanWindowStore: AcuityPlanWindowStore {
        var inner: MemoryAcuityPlanWindowStore
        var cache: TTLCache<AcuityPlanWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanWindowStore, cache: TTLCache<AcuityPlanWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanWindow? {
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

        func save(_ item: AcuityPlanWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanWindow] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanWindowStore(_ inner: MemoryAcuityPlanWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanWindowStore {
        return CachedAcuityPlanWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan windows. Empty fields match all.
    final class AcuityPlanWindowQuery {
        var locale: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanWindow) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AcuityPlanWindow]) -> [AcuityPlanWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanWindows(_ store: any AcuityPlanWindowStore, query: AcuityPlanWindowQuery) -> [AcuityPlanWindow] {
        return query.apply(store.list())
    }
}

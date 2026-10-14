import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert windows by code.
    protocol AlertWindowStore {
        func find(_ code: String) -> AlertWindow?
        func save(_ item: AlertWindow)
        func remove(_ code: String) -> Bool
        func list() -> [AlertWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertWindowStore: AlertWindowStore {
        var items: [String: AlertWindow]
        var order: [String]

        init(items: [String: AlertWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertWindow) {
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

        func list() -> [AlertWindow] {
            var out: [AlertWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertWindowStore() -> any AlertWindowStore {
        return MemoryAlertWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertWindowStore: AlertWindowStore {
        var inner: MemoryAlertWindowStore
        var cache: TTLCache<AlertWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertWindowStore, cache: TTLCache<AlertWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertWindow? {
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

        func save(_ item: AlertWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertWindow] {
            return inner.list()
        }
    }

    static func newCachedAlertWindowStore(_ inner: MemoryAlertWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertWindowStore {
        return CachedAlertWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert windows. Empty fields match all.
    final class AlertWindowQuery {
        var segment: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertWindow) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertWindow]) -> [AlertWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertWindows(_ store: any AlertWindowStore, query: AlertWindowQuery) -> [AlertWindow] {
        return query.apply(store.list())
    }
}

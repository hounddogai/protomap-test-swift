import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped alert windows by code.
    protocol CappedAlertWindowStore {
        func find(_ code: String) -> CappedAlertWindow?
        func save(_ item: CappedAlertWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CappedAlertWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedAlertWindowStore: CappedAlertWindowStore {
        var items: [String: CappedAlertWindow]
        var order: [String]

        init(items: [String: CappedAlertWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedAlertWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedAlertWindow) {
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

        func list() -> [CappedAlertWindow] {
            var out: [CappedAlertWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedAlertWindowStore() -> any CappedAlertWindowStore {
        return MemoryCappedAlertWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedAlertWindowStore: CappedAlertWindowStore {
        var inner: MemoryCappedAlertWindowStore
        var cache: TTLCache<CappedAlertWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedAlertWindowStore, cache: TTLCache<CappedAlertWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedAlertWindow? {
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

        func save(_ item: CappedAlertWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedAlertWindow] {
            return inner.list()
        }
    }

    static func newCachedCappedAlertWindowStore(_ inner: MemoryCappedAlertWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedAlertWindowStore {
        return CachedCappedAlertWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped alert windows. Empty fields match all.
    final class CappedAlertWindowQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedAlertWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedAlertWindow]) -> [CappedAlertWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedAlertWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedAlertWindows(_ store: any CappedAlertWindowStore, query: CappedAlertWindowQuery) -> [CappedAlertWindow] {
        return query.apply(store.list())
    }
}

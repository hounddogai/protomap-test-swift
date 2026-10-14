import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default risk score windows by code.
    protocol DefaultRiskScoreWindowStore {
        func find(_ code: String) -> DefaultRiskScoreWindow?
        func save(_ item: DefaultRiskScoreWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRiskScoreWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRiskScoreWindowStore: DefaultRiskScoreWindowStore {
        var items: [String: DefaultRiskScoreWindow]
        var order: [String]

        init(items: [String: DefaultRiskScoreWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRiskScoreWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRiskScoreWindow) {
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

        func list() -> [DefaultRiskScoreWindow] {
            var out: [DefaultRiskScoreWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRiskScoreWindowStore() -> any DefaultRiskScoreWindowStore {
        return MemoryDefaultRiskScoreWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRiskScoreWindowStore: DefaultRiskScoreWindowStore {
        var inner: MemoryDefaultRiskScoreWindowStore
        var cache: TTLCache<DefaultRiskScoreWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRiskScoreWindowStore, cache: TTLCache<DefaultRiskScoreWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRiskScoreWindow? {
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

        func save(_ item: DefaultRiskScoreWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRiskScoreWindow] {
            return inner.list()
        }
    }

    static func newCachedDefaultRiskScoreWindowStore(_ inner: MemoryDefaultRiskScoreWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRiskScoreWindowStore {
        return CachedDefaultRiskScoreWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default risk score windows. Empty fields match all.
    final class DefaultRiskScoreWindowQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRiskScoreWindow) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRiskScoreWindow]) -> [DefaultRiskScoreWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRiskScoreWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRiskScoreWindows(_ store: any DefaultRiskScoreWindowStore, query: DefaultRiskScoreWindowQuery) -> [DefaultRiskScoreWindow] {
        return query.apply(store.list())
    }
}

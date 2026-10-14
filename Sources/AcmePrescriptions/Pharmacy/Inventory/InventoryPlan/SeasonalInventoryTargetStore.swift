import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal inventory targets by code.
    protocol SeasonalInventoryTargetStore {
        func find(_ code: String) -> SeasonalInventoryTarget?
        func save(_ item: SeasonalInventoryTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalInventoryTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalInventoryTargetStore: SeasonalInventoryTargetStore {
        var items: [String: SeasonalInventoryTarget]
        var order: [String]

        init(items: [String: SeasonalInventoryTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalInventoryTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalInventoryTarget) {
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

        func list() -> [SeasonalInventoryTarget] {
            var out: [SeasonalInventoryTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalInventoryTargetStore() -> any SeasonalInventoryTargetStore {
        return MemorySeasonalInventoryTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalInventoryTargetStore: SeasonalInventoryTargetStore {
        var inner: MemorySeasonalInventoryTargetStore
        var cache: TTLCache<SeasonalInventoryTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalInventoryTargetStore, cache: TTLCache<SeasonalInventoryTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalInventoryTarget? {
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

        func save(_ item: SeasonalInventoryTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalInventoryTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalInventoryTargetStore(_ inner: MemorySeasonalInventoryTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalInventoryTargetStore {
        return CachedSeasonalInventoryTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal inventory targets. Empty fields match all.
    final class SeasonalInventoryTargetQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalInventoryTarget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalInventoryTarget]) -> [SeasonalInventoryTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalInventoryTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalInventoryTargets(_ store: any SeasonalInventoryTargetStore, query: SeasonalInventoryTargetQuery) -> [SeasonalInventoryTarget] {
        return query.apply(store.list())
    }
}

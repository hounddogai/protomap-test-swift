import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal accession adjustments by code.
    protocol SeasonalAccessionAdjustmentStore {
        func find(_ code: String) -> SeasonalAccessionAdjustment?
        func save(_ item: SeasonalAccessionAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalAccessionAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalAccessionAdjustmentStore: SeasonalAccessionAdjustmentStore {
        var items: [String: SeasonalAccessionAdjustment]
        var order: [String]

        init(items: [String: SeasonalAccessionAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalAccessionAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalAccessionAdjustment) {
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

        func list() -> [SeasonalAccessionAdjustment] {
            var out: [SeasonalAccessionAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalAccessionAdjustmentStore() -> any SeasonalAccessionAdjustmentStore {
        return MemorySeasonalAccessionAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalAccessionAdjustmentStore: SeasonalAccessionAdjustmentStore {
        var inner: MemorySeasonalAccessionAdjustmentStore
        var cache: TTLCache<SeasonalAccessionAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalAccessionAdjustmentStore, cache: TTLCache<SeasonalAccessionAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalAccessionAdjustment? {
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

        func save(_ item: SeasonalAccessionAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalAccessionAdjustment] {
            return inner.list()
        }
    }

    static func newCachedSeasonalAccessionAdjustmentStore(_ inner: MemorySeasonalAccessionAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalAccessionAdjustmentStore {
        return CachedSeasonalAccessionAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal accession adjustments. Empty fields match all.
    final class SeasonalAccessionAdjustmentQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalAccessionAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalAccessionAdjustment]) -> [SeasonalAccessionAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalAccessionAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalAccessionAdjustments(_ store: any SeasonalAccessionAdjustmentStore, query: SeasonalAccessionAdjustmentQuery) -> [SeasonalAccessionAdjustment] {
        return query.apply(store.list())
    }
}

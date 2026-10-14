import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy modality cycles by code.
    protocol LegacyModalityCycleStore {
        func find(_ code: String) -> LegacyModalityCycle?
        func save(_ item: LegacyModalityCycle)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyModalityCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyModalityCycleStore: LegacyModalityCycleStore {
        var items: [String: LegacyModalityCycle]
        var order: [String]

        init(items: [String: LegacyModalityCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyModalityCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyModalityCycle) {
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

        func list() -> [LegacyModalityCycle] {
            var out: [LegacyModalityCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyModalityCycleStore() -> any LegacyModalityCycleStore {
        return MemoryLegacyModalityCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyModalityCycleStore: LegacyModalityCycleStore {
        var inner: MemoryLegacyModalityCycleStore
        var cache: TTLCache<LegacyModalityCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyModalityCycleStore, cache: TTLCache<LegacyModalityCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyModalityCycle? {
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

        func save(_ item: LegacyModalityCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyModalityCycle] {
            return inner.list()
        }
    }

    static func newCachedLegacyModalityCycleStore(_ inner: MemoryLegacyModalityCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyModalityCycleStore {
        return CachedLegacyModalityCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy modality cycles. Empty fields match all.
    final class LegacyModalityCycleQuery {
        var country: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMargin: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyModalityCycle) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyModalityCycle]) -> [LegacyModalityCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyModalityCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyModalityCycles(_ store: any LegacyModalityCycleStore, query: LegacyModalityCycleQuery) -> [LegacyModalityCycle] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal disclosure cycles by code.
    protocol SeasonalDisclosureCycleStore {
        func find(_ code: String) -> SeasonalDisclosureCycle?
        func save(_ item: SeasonalDisclosureCycle)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalDisclosureCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalDisclosureCycleStore: SeasonalDisclosureCycleStore {
        var items: [String: SeasonalDisclosureCycle]
        var order: [String]

        init(items: [String: SeasonalDisclosureCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalDisclosureCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalDisclosureCycle) {
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

        func list() -> [SeasonalDisclosureCycle] {
            var out: [SeasonalDisclosureCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalDisclosureCycleStore() -> any SeasonalDisclosureCycleStore {
        return MemorySeasonalDisclosureCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalDisclosureCycleStore: SeasonalDisclosureCycleStore {
        var inner: MemorySeasonalDisclosureCycleStore
        var cache: TTLCache<SeasonalDisclosureCycle>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalDisclosureCycleStore, cache: TTLCache<SeasonalDisclosureCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalDisclosureCycle? {
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

        func save(_ item: SeasonalDisclosureCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalDisclosureCycle] {
            return inner.list()
        }
    }

    static func newCachedSeasonalDisclosureCycleStore(_ inner: MemorySeasonalDisclosureCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalDisclosureCycleStore {
        return CachedSeasonalDisclosureCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal disclosure cycles. Empty fields match all.
    final class SeasonalDisclosureCycleQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalDisclosureCycle) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [SeasonalDisclosureCycle]) -> [SeasonalDisclosureCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalDisclosureCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalDisclosureCycles(_ store: any SeasonalDisclosureCycleStore, query: SeasonalDisclosureCycleQuery) -> [SeasonalDisclosureCycle] {
        return query.apply(store.list())
    }
}

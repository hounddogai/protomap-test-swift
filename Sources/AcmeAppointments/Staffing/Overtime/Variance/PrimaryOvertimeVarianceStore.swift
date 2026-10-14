import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary overtime variances by code.
    protocol PrimaryOvertimeVarianceStore {
        func find(_ code: String) -> PrimaryOvertimeVariance?
        func save(_ item: PrimaryOvertimeVariance)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOvertimeVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOvertimeVarianceStore: PrimaryOvertimeVarianceStore {
        var items: [String: PrimaryOvertimeVariance]
        var order: [String]

        init(items: [String: PrimaryOvertimeVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOvertimeVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOvertimeVariance) {
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

        func list() -> [PrimaryOvertimeVariance] {
            var out: [PrimaryOvertimeVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOvertimeVarianceStore() -> any PrimaryOvertimeVarianceStore {
        return MemoryPrimaryOvertimeVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOvertimeVarianceStore: PrimaryOvertimeVarianceStore {
        var inner: MemoryPrimaryOvertimeVarianceStore
        var cache: TTLCache<PrimaryOvertimeVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOvertimeVarianceStore, cache: TTLCache<PrimaryOvertimeVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOvertimeVariance? {
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

        func save(_ item: PrimaryOvertimeVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOvertimeVariance] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOvertimeVarianceStore(_ inner: MemoryPrimaryOvertimeVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOvertimeVarianceStore {
        return CachedPrimaryOvertimeVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary overtime variances. Empty fields match all.
    final class PrimaryOvertimeVarianceQuery {
        var segment: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOvertimeVariance) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryOvertimeVariance]) -> [PrimaryOvertimeVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOvertimeVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOvertimeVariances(_ store: any PrimaryOvertimeVarianceStore, query: PrimaryOvertimeVarianceQuery) -> [PrimaryOvertimeVariance] {
        return query.apply(store.list())
    }
}

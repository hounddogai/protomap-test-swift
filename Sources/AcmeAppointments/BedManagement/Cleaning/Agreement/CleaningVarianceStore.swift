import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning variances by code.
    protocol CleaningVarianceStore {
        func find(_ code: String) -> CleaningVariance?
        func save(_ item: CleaningVariance)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningVarianceStore: CleaningVarianceStore {
        var items: [String: CleaningVariance]
        var order: [String]

        init(items: [String: CleaningVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningVariance) {
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

        func list() -> [CleaningVariance] {
            var out: [CleaningVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningVarianceStore() -> any CleaningVarianceStore {
        return MemoryCleaningVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningVarianceStore: CleaningVarianceStore {
        var inner: MemoryCleaningVarianceStore
        var cache: TTLCache<CleaningVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningVarianceStore, cache: TTLCache<CleaningVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningVariance? {
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

        func save(_ item: CleaningVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningVariance] {
            return inner.list()
        }
    }

    static func newCachedCleaningVarianceStore(_ inner: MemoryCleaningVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningVarianceStore {
        return CachedCleaningVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning variances. Empty fields match all.
    final class CleaningVarianceQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningVariance]) -> [CleaningVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningVariances(_ store: any CleaningVarianceStore, query: CleaningVarianceQuery) -> [CleaningVariance] {
        return query.apply(store.list())
    }
}

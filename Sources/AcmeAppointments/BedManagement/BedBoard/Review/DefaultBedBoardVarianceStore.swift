import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default bed board variances by code.
    protocol DefaultBedBoardVarianceStore {
        func find(_ code: String) -> DefaultBedBoardVariance?
        func save(_ item: DefaultBedBoardVariance)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultBedBoardVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultBedBoardVarianceStore: DefaultBedBoardVarianceStore {
        var items: [String: DefaultBedBoardVariance]
        var order: [String]

        init(items: [String: DefaultBedBoardVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultBedBoardVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultBedBoardVariance) {
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

        func list() -> [DefaultBedBoardVariance] {
            var out: [DefaultBedBoardVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultBedBoardVarianceStore() -> any DefaultBedBoardVarianceStore {
        return MemoryDefaultBedBoardVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultBedBoardVarianceStore: DefaultBedBoardVarianceStore {
        var inner: MemoryDefaultBedBoardVarianceStore
        var cache: TTLCache<DefaultBedBoardVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultBedBoardVarianceStore, cache: TTLCache<DefaultBedBoardVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultBedBoardVariance? {
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

        func save(_ item: DefaultBedBoardVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultBedBoardVariance] {
            return inner.list()
        }
    }

    static func newCachedDefaultBedBoardVarianceStore(_ inner: MemoryDefaultBedBoardVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultBedBoardVarianceStore {
        return CachedDefaultBedBoardVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default bed board variances. Empty fields match all.
    final class DefaultBedBoardVarianceQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultBedBoardVariance) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DefaultBedBoardVariance]) -> [DefaultBedBoardVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultBedBoardVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultBedBoardVariances(_ store: any DefaultBedBoardVarianceStore, query: DefaultBedBoardVarianceQuery) -> [DefaultBedBoardVariance] {
        return query.apply(store.list())
    }
}

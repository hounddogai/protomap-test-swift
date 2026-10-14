import AcmePlatform
import Foundation

extension Labs {
    /// Keeps strict specimen variances by code.
    protocol StrictSpecimenVarianceStore {
        func find(_ code: String) -> StrictSpecimenVariance?
        func save(_ item: StrictSpecimenVariance)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSpecimenVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSpecimenVarianceStore: StrictSpecimenVarianceStore {
        var items: [String: StrictSpecimenVariance]
        var order: [String]

        init(items: [String: StrictSpecimenVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSpecimenVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSpecimenVariance) {
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

        func list() -> [StrictSpecimenVariance] {
            var out: [StrictSpecimenVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSpecimenVarianceStore() -> any StrictSpecimenVarianceStore {
        return MemoryStrictSpecimenVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSpecimenVarianceStore: StrictSpecimenVarianceStore {
        var inner: MemoryStrictSpecimenVarianceStore
        var cache: TTLCache<StrictSpecimenVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSpecimenVarianceStore, cache: TTLCache<StrictSpecimenVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSpecimenVariance? {
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

        func save(_ item: StrictSpecimenVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSpecimenVariance] {
            return inner.list()
        }
    }

    static func newCachedStrictSpecimenVarianceStore(_ inner: MemoryStrictSpecimenVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSpecimenVarianceStore {
        return CachedStrictSpecimenVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict specimen variances. Empty fields match all.
    final class StrictSpecimenVarianceQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSpecimenVariance) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSpecimenVariance]) -> [StrictSpecimenVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSpecimenVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSpecimenVariances(_ store: any StrictSpecimenVarianceStore, query: StrictSpecimenVarianceQuery) -> [StrictSpecimenVariance] {
        return query.apply(store.list())
    }
}

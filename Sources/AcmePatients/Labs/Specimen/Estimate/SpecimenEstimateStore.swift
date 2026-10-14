import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen estimates by code.
    protocol SpecimenEstimateStore {
        func find(_ code: String) -> SpecimenEstimate?
        func save(_ item: SpecimenEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenEstimateStore: SpecimenEstimateStore {
        var items: [String: SpecimenEstimate]
        var order: [String]

        init(items: [String: SpecimenEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenEstimate) {
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

        func list() -> [SpecimenEstimate] {
            var out: [SpecimenEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenEstimateStore() -> any SpecimenEstimateStore {
        return MemorySpecimenEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenEstimateStore: SpecimenEstimateStore {
        var inner: MemorySpecimenEstimateStore
        var cache: TTLCache<SpecimenEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenEstimateStore, cache: TTLCache<SpecimenEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenEstimate? {
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

        func save(_ item: SpecimenEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenEstimate] {
            return inner.list()
        }
    }

    static func newCachedSpecimenEstimateStore(_ inner: MemorySpecimenEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenEstimateStore {
        return CachedSpecimenEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen estimates. Empty fields match all.
    final class SpecimenEstimateQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenEstimate]) -> [SpecimenEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenEstimates(_ store: any SpecimenEstimateStore, query: SpecimenEstimateQuery) -> [SpecimenEstimate] {
        return query.apply(store.list())
    }
}

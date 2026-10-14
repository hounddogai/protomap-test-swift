import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program estimates by code.
    protocol ProgramEstimateStore {
        func find(_ code: String) -> ProgramEstimate?
        func save(_ item: ProgramEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramEstimateStore: ProgramEstimateStore {
        var items: [String: ProgramEstimate]
        var order: [String]

        init(items: [String: ProgramEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramEstimate) {
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

        func list() -> [ProgramEstimate] {
            var out: [ProgramEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramEstimateStore() -> any ProgramEstimateStore {
        return MemoryProgramEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramEstimateStore: ProgramEstimateStore {
        var inner: MemoryProgramEstimateStore
        var cache: TTLCache<ProgramEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramEstimateStore, cache: TTLCache<ProgramEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramEstimate? {
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

        func save(_ item: ProgramEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramEstimate] {
            return inner.list()
        }
    }

    static func newCachedProgramEstimateStore(_ inner: MemoryProgramEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramEstimateStore {
        return CachedProgramEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program estimates. Empty fields match all.
    final class ProgramEstimateQuery {
        var segment: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCost: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramEstimate]) -> [ProgramEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramEstimates(_ store: any ProgramEstimateStore, query: ProgramEstimateQuery) -> [ProgramEstimate] {
        return query.apply(store.list())
    }
}

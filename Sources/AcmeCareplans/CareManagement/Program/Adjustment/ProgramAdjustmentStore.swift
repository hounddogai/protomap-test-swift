import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program adjustments by code.
    protocol ProgramAdjustmentStore {
        func find(_ code: String) -> ProgramAdjustment?
        func save(_ item: ProgramAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramAdjustmentStore: ProgramAdjustmentStore {
        var items: [String: ProgramAdjustment]
        var order: [String]

        init(items: [String: ProgramAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramAdjustment) {
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

        func list() -> [ProgramAdjustment] {
            var out: [ProgramAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramAdjustmentStore() -> any ProgramAdjustmentStore {
        return MemoryProgramAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramAdjustmentStore: ProgramAdjustmentStore {
        var inner: MemoryProgramAdjustmentStore
        var cache: TTLCache<ProgramAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramAdjustmentStore, cache: TTLCache<ProgramAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramAdjustment? {
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

        func save(_ item: ProgramAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramAdjustment] {
            return inner.list()
        }
    }

    static func newCachedProgramAdjustmentStore(_ inner: MemoryProgramAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramAdjustmentStore {
        return CachedProgramAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program adjustments. Empty fields match all.
    final class ProgramAdjustmentQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramAdjustment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ProgramAdjustment]) -> [ProgramAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramAdjustments(_ store: any ProgramAdjustmentStore, query: ProgramAdjustmentQuery) -> [ProgramAdjustment] {
        return query.apply(store.list())
    }
}

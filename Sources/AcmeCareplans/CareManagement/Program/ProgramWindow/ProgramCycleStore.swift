import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program cycles by code.
    protocol ProgramCycleStore {
        func find(_ code: String) -> ProgramCycle?
        func save(_ item: ProgramCycle)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramCycleStore: ProgramCycleStore {
        var items: [String: ProgramCycle]
        var order: [String]

        init(items: [String: ProgramCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramCycle) {
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

        func list() -> [ProgramCycle] {
            var out: [ProgramCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramCycleStore() -> any ProgramCycleStore {
        return MemoryProgramCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramCycleStore: ProgramCycleStore {
        var inner: MemoryProgramCycleStore
        var cache: TTLCache<ProgramCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramCycleStore, cache: TTLCache<ProgramCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramCycle? {
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

        func save(_ item: ProgramCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramCycle] {
            return inner.list()
        }
    }

    static func newCachedProgramCycleStore(_ inner: MemoryProgramCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramCycleStore {
        return CachedProgramCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program cycles. Empty fields match all.
    final class ProgramCycleQuery {
        var ward: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minScore: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ProgramCycle]) -> [ProgramCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramCycles(_ store: any ProgramCycleStore, query: ProgramCycleQuery) -> [ProgramCycle] {
        return query.apply(store.list())
    }
}

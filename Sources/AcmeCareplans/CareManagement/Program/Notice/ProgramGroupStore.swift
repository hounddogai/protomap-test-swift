import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program groups by code.
    protocol ProgramGroupStore {
        func find(_ code: String) -> ProgramGroup?
        func save(_ item: ProgramGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramGroupStore: ProgramGroupStore {
        var items: [String: ProgramGroup]
        var order: [String]

        init(items: [String: ProgramGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramGroup) {
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

        func list() -> [ProgramGroup] {
            var out: [ProgramGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramGroupStore() -> any ProgramGroupStore {
        return MemoryProgramGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramGroupStore: ProgramGroupStore {
        var inner: MemoryProgramGroupStore
        var cache: TTLCache<ProgramGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramGroupStore, cache: TTLCache<ProgramGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramGroup? {
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

        func save(_ item: ProgramGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramGroup] {
            return inner.list()
        }
    }

    static func newCachedProgramGroupStore(_ inner: MemoryProgramGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramGroupStore {
        return CachedProgramGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program groups. Empty fields match all.
    final class ProgramGroupQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ProgramGroup]) -> [ProgramGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramGroups(_ store: any ProgramGroupStore, query: ProgramGroupQuery) -> [ProgramGroup] {
        return query.apply(store.list())
    }
}

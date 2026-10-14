import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program windows by code.
    protocol ProgramWindowStore {
        func find(_ code: String) -> ProgramWindow?
        func save(_ item: ProgramWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramWindowStore: ProgramWindowStore {
        var items: [String: ProgramWindow]
        var order: [String]

        init(items: [String: ProgramWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramWindow) {
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

        func list() -> [ProgramWindow] {
            var out: [ProgramWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramWindowStore() -> any ProgramWindowStore {
        return MemoryProgramWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramWindowStore: ProgramWindowStore {
        var inner: MemoryProgramWindowStore
        var cache: TTLCache<ProgramWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramWindowStore, cache: TTLCache<ProgramWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramWindow? {
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

        func save(_ item: ProgramWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramWindow] {
            return inner.list()
        }
    }

    static func newCachedProgramWindowStore(_ inner: MemoryProgramWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramWindowStore {
        return CachedProgramWindowStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program windows. Empty fields match all.
    final class ProgramWindowQuery {
        var unit: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramWindow) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [ProgramWindow]) -> [ProgramWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramWindows(_ store: any ProgramWindowStore, query: ProgramWindowQuery) -> [ProgramWindow] {
        return query.apply(store.list())
    }
}

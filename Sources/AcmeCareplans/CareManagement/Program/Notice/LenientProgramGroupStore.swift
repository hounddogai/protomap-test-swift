import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient program groups by code.
    protocol LenientProgramGroupStore {
        func find(_ code: String) -> LenientProgramGroup?
        func save(_ item: LenientProgramGroup)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProgramGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProgramGroupStore: LenientProgramGroupStore {
        var items: [String: LenientProgramGroup]
        var order: [String]

        init(items: [String: LenientProgramGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProgramGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProgramGroup) {
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

        func list() -> [LenientProgramGroup] {
            var out: [LenientProgramGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProgramGroupStore() -> any LenientProgramGroupStore {
        return MemoryLenientProgramGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProgramGroupStore: LenientProgramGroupStore {
        var inner: MemoryLenientProgramGroupStore
        var cache: TTLCache<LenientProgramGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProgramGroupStore, cache: TTLCache<LenientProgramGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProgramGroup? {
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

        func save(_ item: LenientProgramGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProgramGroup] {
            return inner.list()
        }
    }

    static func newCachedLenientProgramGroupStore(_ inner: MemoryLenientProgramGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProgramGroupStore {
        return CachedLenientProgramGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient program groups. Empty fields match all.
    final class LenientProgramGroupQuery {
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

        func matches(_ item: LenientProgramGroup) -> Bool {
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

        func apply(_ items: [LenientProgramGroup]) -> [LenientProgramGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProgramGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProgramGroups(_ store: any LenientProgramGroupStore, query: LenientProgramGroupQuery) -> [LenientProgramGroup] {
        return query.apply(store.list())
    }
}

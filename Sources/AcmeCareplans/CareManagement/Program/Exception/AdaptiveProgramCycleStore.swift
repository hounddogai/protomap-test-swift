import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive program cycles by code.
    protocol AdaptiveProgramCycleStore {
        func find(_ code: String) -> AdaptiveProgramCycle?
        func save(_ item: AdaptiveProgramCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveProgramCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveProgramCycleStore: AdaptiveProgramCycleStore {
        var items: [String: AdaptiveProgramCycle]
        var order: [String]

        init(items: [String: AdaptiveProgramCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveProgramCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveProgramCycle) {
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

        func list() -> [AdaptiveProgramCycle] {
            var out: [AdaptiveProgramCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveProgramCycleStore() -> any AdaptiveProgramCycleStore {
        return MemoryAdaptiveProgramCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveProgramCycleStore: AdaptiveProgramCycleStore {
        var inner: MemoryAdaptiveProgramCycleStore
        var cache: TTLCache<AdaptiveProgramCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveProgramCycleStore, cache: TTLCache<AdaptiveProgramCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveProgramCycle? {
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

        func save(_ item: AdaptiveProgramCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveProgramCycle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveProgramCycleStore(_ inner: MemoryAdaptiveProgramCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveProgramCycleStore {
        return CachedAdaptiveProgramCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive program cycles. Empty fields match all.
    final class AdaptiveProgramCycleQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveProgramCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveProgramCycle]) -> [AdaptiveProgramCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveProgramCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveProgramCycles(_ store: any AdaptiveProgramCycleStore, query: AdaptiveProgramCycleQuery) -> [AdaptiveProgramCycle] {
        return query.apply(store.list())
    }
}

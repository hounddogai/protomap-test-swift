import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps adaptive float pool cycles by code.
    protocol AdaptiveFloatPoolCycleStore {
        func find(_ code: String) -> AdaptiveFloatPoolCycle?
        func save(_ item: AdaptiveFloatPoolCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFloatPoolCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFloatPoolCycleStore: AdaptiveFloatPoolCycleStore {
        var items: [String: AdaptiveFloatPoolCycle]
        var order: [String]

        init(items: [String: AdaptiveFloatPoolCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFloatPoolCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFloatPoolCycle) {
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

        func list() -> [AdaptiveFloatPoolCycle] {
            var out: [AdaptiveFloatPoolCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFloatPoolCycleStore() -> any AdaptiveFloatPoolCycleStore {
        return MemoryAdaptiveFloatPoolCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFloatPoolCycleStore: AdaptiveFloatPoolCycleStore {
        var inner: MemoryAdaptiveFloatPoolCycleStore
        var cache: TTLCache<AdaptiveFloatPoolCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFloatPoolCycleStore, cache: TTLCache<AdaptiveFloatPoolCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFloatPoolCycle? {
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

        func save(_ item: AdaptiveFloatPoolCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFloatPoolCycle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFloatPoolCycleStore(_ inner: MemoryAdaptiveFloatPoolCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFloatPoolCycleStore {
        return CachedAdaptiveFloatPoolCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive float pool cycles. Empty fields match all.
    final class AdaptiveFloatPoolCycleQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFloatPoolCycle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFloatPoolCycle]) -> [AdaptiveFloatPoolCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFloatPoolCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFloatPoolCycles(_ store: any AdaptiveFloatPoolCycleStore, query: AdaptiveFloatPoolCycleQuery) -> [AdaptiveFloatPoolCycle] {
        return query.apply(store.list())
    }
}

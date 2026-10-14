import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap targets by code.
    protocol CareGapTargetStore {
        func find(_ code: String) -> CareGapTarget?
        func save(_ item: CareGapTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapTargetStore: CareGapTargetStore {
        var items: [String: CareGapTarget]
        var order: [String]

        init(items: [String: CareGapTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapTarget) {
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

        func list() -> [CareGapTarget] {
            var out: [CareGapTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapTargetStore() -> any CareGapTargetStore {
        return MemoryCareGapTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapTargetStore: CareGapTargetStore {
        var inner: MemoryCareGapTargetStore
        var cache: TTLCache<CareGapTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapTargetStore, cache: TTLCache<CareGapTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapTarget? {
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

        func save(_ item: CareGapTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapTarget] {
            return inner.list()
        }
    }

    static func newCachedCareGapTargetStore(_ inner: MemoryCareGapTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapTargetStore {
        return CachedCareGapTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap targets. Empty fields match all.
    final class CareGapTargetQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapTarget]) -> [CareGapTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapTargets(_ store: any CareGapTargetStore, query: CareGapTargetQuery) -> [CareGapTarget] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist rollups by code.
    protocol WorklistRollupStore {
        func find(_ code: String) -> WorklistRollup?
        func save(_ item: WorklistRollup)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistRollupStore: WorklistRollupStore {
        var items: [String: WorklistRollup]
        var order: [String]

        init(items: [String: WorklistRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistRollup) {
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

        func list() -> [WorklistRollup] {
            var out: [WorklistRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistRollupStore() -> any WorklistRollupStore {
        return MemoryWorklistRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistRollupStore: WorklistRollupStore {
        var inner: MemoryWorklistRollupStore
        var cache: TTLCache<WorklistRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistRollupStore, cache: TTLCache<WorklistRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistRollup? {
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

        func save(_ item: WorklistRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistRollup] {
            return inner.list()
        }
    }

    static func newCachedWorklistRollupStore(_ inner: MemoryWorklistRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistRollupStore {
        return CachedWorklistRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist rollups. Empty fields match all.
    final class WorklistRollupQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistRollup) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [WorklistRollup]) -> [WorklistRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistRollups(_ store: any WorklistRollupStore, query: WorklistRollupQuery) -> [WorklistRollup] {
        return query.apply(store.list())
    }
}

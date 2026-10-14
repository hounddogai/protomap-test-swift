import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global acuity plan exceptions by code.
    protocol GlobalAcuityPlanExceptionStore {
        func find(_ code: String) -> GlobalAcuityPlanException?
        func save(_ item: GlobalAcuityPlanException)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAcuityPlanException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAcuityPlanExceptionStore: GlobalAcuityPlanExceptionStore {
        var items: [String: GlobalAcuityPlanException]
        var order: [String]

        init(items: [String: GlobalAcuityPlanException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAcuityPlanException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAcuityPlanException) {
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

        func list() -> [GlobalAcuityPlanException] {
            var out: [GlobalAcuityPlanException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAcuityPlanExceptionStore() -> any GlobalAcuityPlanExceptionStore {
        return MemoryGlobalAcuityPlanExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAcuityPlanExceptionStore: GlobalAcuityPlanExceptionStore {
        var inner: MemoryGlobalAcuityPlanExceptionStore
        var cache: TTLCache<GlobalAcuityPlanException>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAcuityPlanExceptionStore, cache: TTLCache<GlobalAcuityPlanException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAcuityPlanException? {
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

        func save(_ item: GlobalAcuityPlanException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAcuityPlanException] {
            return inner.list()
        }
    }

    static func newCachedGlobalAcuityPlanExceptionStore(_ inner: MemoryGlobalAcuityPlanExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAcuityPlanExceptionStore {
        return CachedGlobalAcuityPlanExceptionStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global acuity plan exceptions. Empty fields match all.
    final class GlobalAcuityPlanExceptionQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAcuityPlanException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAcuityPlanException]) -> [GlobalAcuityPlanException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAcuityPlanException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAcuityPlanExceptions(_ store: any GlobalAcuityPlanExceptionStore, query: GlobalAcuityPlanExceptionQuery) -> [GlobalAcuityPlanException] {
        return query.apply(store.list())
    }
}

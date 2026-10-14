import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen targets by code.
    protocol SpecimenTargetStore {
        func find(_ code: String) -> SpecimenTarget?
        func save(_ item: SpecimenTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenTargetStore: SpecimenTargetStore {
        var items: [String: SpecimenTarget]
        var order: [String]

        init(items: [String: SpecimenTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenTarget) {
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

        func list() -> [SpecimenTarget] {
            var out: [SpecimenTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenTargetStore() -> any SpecimenTargetStore {
        return MemorySpecimenTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenTargetStore: SpecimenTargetStore {
        var inner: MemorySpecimenTargetStore
        var cache: TTLCache<SpecimenTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenTargetStore, cache: TTLCache<SpecimenTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenTarget? {
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

        func save(_ item: SpecimenTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenTarget] {
            return inner.list()
        }
    }

    static func newCachedSpecimenTargetStore(_ inner: MemorySpecimenTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenTargetStore {
        return CachedSpecimenTargetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen targets. Empty fields match all.
    final class SpecimenTargetQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenTarget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenTarget]) -> [SpecimenTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenTargets(_ store: any SpecimenTargetStore, query: SpecimenTargetQuery) -> [SpecimenTarget] {
        return query.apply(store.list())
    }
}

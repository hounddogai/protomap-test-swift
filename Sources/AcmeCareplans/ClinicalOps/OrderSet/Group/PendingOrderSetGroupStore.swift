import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending order set groups by code.
    protocol PendingOrderSetGroupStore {
        func find(_ code: String) -> PendingOrderSetGroup?
        func save(_ item: PendingOrderSetGroup)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOrderSetGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOrderSetGroupStore: PendingOrderSetGroupStore {
        var items: [String: PendingOrderSetGroup]
        var order: [String]

        init(items: [String: PendingOrderSetGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOrderSetGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOrderSetGroup) {
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

        func list() -> [PendingOrderSetGroup] {
            var out: [PendingOrderSetGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOrderSetGroupStore() -> any PendingOrderSetGroupStore {
        return MemoryPendingOrderSetGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOrderSetGroupStore: PendingOrderSetGroupStore {
        var inner: MemoryPendingOrderSetGroupStore
        var cache: TTLCache<PendingOrderSetGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOrderSetGroupStore, cache: TTLCache<PendingOrderSetGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOrderSetGroup? {
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

        func save(_ item: PendingOrderSetGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOrderSetGroup] {
            return inner.list()
        }
    }

    static func newCachedPendingOrderSetGroupStore(_ inner: MemoryPendingOrderSetGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOrderSetGroupStore {
        return CachedPendingOrderSetGroupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending order set groups. Empty fields match all.
    final class PendingOrderSetGroupQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOrderSetGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PendingOrderSetGroup]) -> [PendingOrderSetGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOrderSetGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOrderSetGroups(_ store: any PendingOrderSetGroupStore, query: PendingOrderSetGroupQuery) -> [PendingOrderSetGroup] {
        return query.apply(store.list())
    }
}

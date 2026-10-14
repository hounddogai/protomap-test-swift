import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps primary care gap groups by code.
    protocol PrimaryCareGapGroupStore {
        func find(_ code: String) -> PrimaryCareGapGroup?
        func save(_ item: PrimaryCareGapGroup)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCareGapGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCareGapGroupStore: PrimaryCareGapGroupStore {
        var items: [String: PrimaryCareGapGroup]
        var order: [String]

        init(items: [String: PrimaryCareGapGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCareGapGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCareGapGroup) {
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

        func list() -> [PrimaryCareGapGroup] {
            var out: [PrimaryCareGapGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCareGapGroupStore() -> any PrimaryCareGapGroupStore {
        return MemoryPrimaryCareGapGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCareGapGroupStore: PrimaryCareGapGroupStore {
        var inner: MemoryPrimaryCareGapGroupStore
        var cache: TTLCache<PrimaryCareGapGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCareGapGroupStore, cache: TTLCache<PrimaryCareGapGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCareGapGroup? {
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

        func save(_ item: PrimaryCareGapGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCareGapGroup] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCareGapGroupStore(_ inner: MemoryPrimaryCareGapGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCareGapGroupStore {
        return CachedPrimaryCareGapGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary care gap groups. Empty fields match all.
    final class PrimaryCareGapGroupQuery {
        var category: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minVersion: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCareGapGroup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PrimaryCareGapGroup]) -> [PrimaryCareGapGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCareGapGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCareGapGroups(_ store: any PrimaryCareGapGroupStore, query: PrimaryCareGapGroupQuery) -> [PrimaryCareGapGroup] {
        return query.apply(store.list())
    }
}

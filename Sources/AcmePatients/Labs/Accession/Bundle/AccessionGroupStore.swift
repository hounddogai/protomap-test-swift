import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession groups by code.
    protocol AccessionGroupStore {
        func find(_ code: String) -> AccessionGroup?
        func save(_ item: AccessionGroup)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionGroupStore: AccessionGroupStore {
        var items: [String: AccessionGroup]
        var order: [String]

        init(items: [String: AccessionGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionGroup) {
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

        func list() -> [AccessionGroup] {
            var out: [AccessionGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionGroupStore() -> any AccessionGroupStore {
        return MemoryAccessionGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionGroupStore: AccessionGroupStore {
        var inner: MemoryAccessionGroupStore
        var cache: TTLCache<AccessionGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionGroupStore, cache: TTLCache<AccessionGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionGroup? {
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

        func save(_ item: AccessionGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionGroup] {
            return inner.list()
        }
    }

    static func newCachedAccessionGroupStore(_ inner: MemoryAccessionGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionGroupStore {
        return CachedAccessionGroupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession groups. Empty fields match all.
    final class AccessionGroupQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AccessionGroup]) -> [AccessionGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionGroups(_ store: any AccessionGroupStore, query: AccessionGroupQuery) -> [AccessionGroup] {
        return query.apply(store.list())
    }
}

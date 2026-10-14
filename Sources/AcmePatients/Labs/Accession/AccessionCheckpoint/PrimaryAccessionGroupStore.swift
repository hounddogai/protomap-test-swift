import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary accession groups by code.
    protocol PrimaryAccessionGroupStore {
        func find(_ code: String) -> PrimaryAccessionGroup?
        func save(_ item: PrimaryAccessionGroup)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAccessionGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAccessionGroupStore: PrimaryAccessionGroupStore {
        var items: [String: PrimaryAccessionGroup]
        var order: [String]

        init(items: [String: PrimaryAccessionGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAccessionGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAccessionGroup) {
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

        func list() -> [PrimaryAccessionGroup] {
            var out: [PrimaryAccessionGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAccessionGroupStore() -> any PrimaryAccessionGroupStore {
        return MemoryPrimaryAccessionGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAccessionGroupStore: PrimaryAccessionGroupStore {
        var inner: MemoryPrimaryAccessionGroupStore
        var cache: TTLCache<PrimaryAccessionGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAccessionGroupStore, cache: TTLCache<PrimaryAccessionGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAccessionGroup? {
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

        func save(_ item: PrimaryAccessionGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAccessionGroup] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAccessionGroupStore(_ inner: MemoryPrimaryAccessionGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAccessionGroupStore {
        return CachedPrimaryAccessionGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary accession groups. Empty fields match all.
    final class PrimaryAccessionGroupQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAccessionGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAccessionGroup]) -> [PrimaryAccessionGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAccessionGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAccessionGroups(_ store: any PrimaryAccessionGroupStore, query: PrimaryAccessionGroupQuery) -> [PrimaryAccessionGroup] {
        return query.apply(store.list())
    }
}

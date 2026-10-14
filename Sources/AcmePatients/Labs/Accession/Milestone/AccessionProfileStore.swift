import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession profiles by code.
    protocol AccessionProfileStore {
        func find(_ code: String) -> AccessionProfile?
        func save(_ item: AccessionProfile)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionProfileStore: AccessionProfileStore {
        var items: [String: AccessionProfile]
        var order: [String]

        init(items: [String: AccessionProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionProfile) {
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

        func list() -> [AccessionProfile] {
            var out: [AccessionProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionProfileStore() -> any AccessionProfileStore {
        return MemoryAccessionProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionProfileStore: AccessionProfileStore {
        var inner: MemoryAccessionProfileStore
        var cache: TTLCache<AccessionProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionProfileStore, cache: TTLCache<AccessionProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionProfile? {
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

        func save(_ item: AccessionProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionProfile] {
            return inner.list()
        }
    }

    static func newCachedAccessionProfileStore(_ inner: MemoryAccessionProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionProfileStore {
        return CachedAccessionProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession profiles. Empty fields match all.
    final class AccessionProfileQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AccessionProfile]) -> [AccessionProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionProfiles(_ store: any AccessionProfileStore, query: AccessionProfileQuery) -> [AccessionProfile] {
        return query.apply(store.list())
    }
}

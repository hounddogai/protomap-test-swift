import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global disclosure profiles by code.
    protocol GlobalDisclosureProfileStore {
        func find(_ code: String) -> GlobalDisclosureProfile?
        func save(_ item: GlobalDisclosureProfile)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDisclosureProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDisclosureProfileStore: GlobalDisclosureProfileStore {
        var items: [String: GlobalDisclosureProfile]
        var order: [String]

        init(items: [String: GlobalDisclosureProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDisclosureProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDisclosureProfile) {
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

        func list() -> [GlobalDisclosureProfile] {
            var out: [GlobalDisclosureProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDisclosureProfileStore() -> any GlobalDisclosureProfileStore {
        return MemoryGlobalDisclosureProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDisclosureProfileStore: GlobalDisclosureProfileStore {
        var inner: MemoryGlobalDisclosureProfileStore
        var cache: TTLCache<GlobalDisclosureProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDisclosureProfileStore, cache: TTLCache<GlobalDisclosureProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDisclosureProfile? {
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

        func save(_ item: GlobalDisclosureProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDisclosureProfile] {
            return inner.list()
        }
    }

    static func newCachedGlobalDisclosureProfileStore(_ inner: MemoryGlobalDisclosureProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDisclosureProfileStore {
        return CachedGlobalDisclosureProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global disclosure profiles. Empty fields match all.
    final class GlobalDisclosureProfileQuery {
        var category: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDisclosureProfile) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDisclosureProfile]) -> [GlobalDisclosureProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDisclosureProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDisclosureProfiles(_ store: any GlobalDisclosureProfileStore, query: GlobalDisclosureProfileQuery) -> [GlobalDisclosureProfile] {
        return query.apply(store.list())
    }
}

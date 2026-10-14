import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation profiles by code.
    protocol RevocationProfileStore {
        func find(_ code: String) -> RevocationProfile?
        func save(_ item: RevocationProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationProfileStore: RevocationProfileStore {
        var items: [String: RevocationProfile]
        var order: [String]

        init(items: [String: RevocationProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationProfile) {
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

        func list() -> [RevocationProfile] {
            var out: [RevocationProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationProfileStore() -> any RevocationProfileStore {
        return MemoryRevocationProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationProfileStore: RevocationProfileStore {
        var inner: MemoryRevocationProfileStore
        var cache: TTLCache<RevocationProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationProfileStore, cache: TTLCache<RevocationProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationProfile? {
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

        func save(_ item: RevocationProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationProfile] {
            return inner.list()
        }
    }

    static func newCachedRevocationProfileStore(_ inner: MemoryRevocationProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationProfileStore {
        return CachedRevocationProfileStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation profiles. Empty fields match all.
    final class RevocationProfileQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationProfile]) -> [RevocationProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationProfiles(_ store: any RevocationProfileStore, query: RevocationProfileQuery) -> [RevocationProfile] {
        return query.apply(store.list())
    }
}

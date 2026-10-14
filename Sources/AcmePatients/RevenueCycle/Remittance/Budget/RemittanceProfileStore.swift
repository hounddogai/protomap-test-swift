import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance profiles by code.
    protocol RemittanceProfileStore {
        func find(_ code: String) -> RemittanceProfile?
        func save(_ item: RemittanceProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceProfileStore: RemittanceProfileStore {
        var items: [String: RemittanceProfile]
        var order: [String]

        init(items: [String: RemittanceProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceProfile) {
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

        func list() -> [RemittanceProfile] {
            var out: [RemittanceProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceProfileStore() -> any RemittanceProfileStore {
        return MemoryRemittanceProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceProfileStore: RemittanceProfileStore {
        var inner: MemoryRemittanceProfileStore
        var cache: TTLCache<RemittanceProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceProfileStore, cache: TTLCache<RemittanceProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceProfile? {
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

        func save(_ item: RemittanceProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceProfile] {
            return inner.list()
        }
    }

    static func newCachedRemittanceProfileStore(_ inner: MemoryRemittanceProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceProfileStore {
        return CachedRemittanceProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance profiles. Empty fields match all.
    final class RemittanceProfileQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RemittanceProfile]) -> [RemittanceProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceProfiles(_ store: any RemittanceProfileStore, query: RemittanceProfileQuery) -> [RemittanceProfile] {
        return query.apply(store.list())
    }
}

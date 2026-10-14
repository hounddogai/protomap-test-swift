import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending accession profiles by code.
    protocol PendingAccessionProfileStore {
        func find(_ code: String) -> PendingAccessionProfile?
        func save(_ item: PendingAccessionProfile)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAccessionProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAccessionProfileStore: PendingAccessionProfileStore {
        var items: [String: PendingAccessionProfile]
        var order: [String]

        init(items: [String: PendingAccessionProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAccessionProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAccessionProfile) {
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

        func list() -> [PendingAccessionProfile] {
            var out: [PendingAccessionProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAccessionProfileStore() -> any PendingAccessionProfileStore {
        return MemoryPendingAccessionProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAccessionProfileStore: PendingAccessionProfileStore {
        var inner: MemoryPendingAccessionProfileStore
        var cache: TTLCache<PendingAccessionProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAccessionProfileStore, cache: TTLCache<PendingAccessionProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAccessionProfile? {
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

        func save(_ item: PendingAccessionProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAccessionProfile] {
            return inner.list()
        }
    }

    static func newCachedPendingAccessionProfileStore(_ inner: MemoryPendingAccessionProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAccessionProfileStore {
        return CachedPendingAccessionProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending accession profiles. Empty fields match all.
    final class PendingAccessionProfileQuery {
        var segment: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAccessionProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [PendingAccessionProfile]) -> [PendingAccessionProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAccessionProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAccessionProfiles(_ store: any PendingAccessionProfileStore, query: PendingAccessionProfileQuery) -> [PendingAccessionProfile] {
        return query.apply(store.list())
    }
}

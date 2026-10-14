import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial profiles by code.
    protocol DenialProfileStore {
        func find(_ code: String) -> DenialProfile?
        func save(_ item: DenialProfile)
        func remove(_ code: String) -> Bool
        func list() -> [DenialProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialProfileStore: DenialProfileStore {
        var items: [String: DenialProfile]
        var order: [String]

        init(items: [String: DenialProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialProfile) {
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

        func list() -> [DenialProfile] {
            var out: [DenialProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialProfileStore() -> any DenialProfileStore {
        return MemoryDenialProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialProfileStore: DenialProfileStore {
        var inner: MemoryDenialProfileStore
        var cache: TTLCache<DenialProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialProfileStore, cache: TTLCache<DenialProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialProfile? {
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

        func save(_ item: DenialProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialProfile] {
            return inner.list()
        }
    }

    static func newCachedDenialProfileStore(_ inner: MemoryDenialProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialProfileStore {
        return CachedDenialProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial profiles. Empty fields match all.
    final class DenialProfileQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialProfile]) -> [DenialProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialProfiles(_ store: any DenialProfileStore, query: DenialProfileQuery) -> [DenialProfile] {
        return query.apply(store.list())
    }
}

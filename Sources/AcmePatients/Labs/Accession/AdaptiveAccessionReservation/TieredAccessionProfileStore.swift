import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered accession profiles by code.
    protocol TieredAccessionProfileStore {
        func find(_ code: String) -> TieredAccessionProfile?
        func save(_ item: TieredAccessionProfile)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAccessionProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAccessionProfileStore: TieredAccessionProfileStore {
        var items: [String: TieredAccessionProfile]
        var order: [String]

        init(items: [String: TieredAccessionProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAccessionProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAccessionProfile) {
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

        func list() -> [TieredAccessionProfile] {
            var out: [TieredAccessionProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAccessionProfileStore() -> any TieredAccessionProfileStore {
        return MemoryTieredAccessionProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAccessionProfileStore: TieredAccessionProfileStore {
        var inner: MemoryTieredAccessionProfileStore
        var cache: TTLCache<TieredAccessionProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAccessionProfileStore, cache: TTLCache<TieredAccessionProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAccessionProfile? {
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

        func save(_ item: TieredAccessionProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAccessionProfile] {
            return inner.list()
        }
    }

    static func newCachedTieredAccessionProfileStore(_ inner: MemoryTieredAccessionProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAccessionProfileStore {
        return CachedTieredAccessionProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered accession profiles. Empty fields match all.
    final class TieredAccessionProfileQuery {
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

        func matches(_ item: TieredAccessionProfile) -> Bool {
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

        func apply(_ items: [TieredAccessionProfile]) -> [TieredAccessionProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAccessionProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAccessionProfiles(_ store: any TieredAccessionProfileStore, query: TieredAccessionProfileQuery) -> [TieredAccessionProfile] {
        return query.apply(store.list())
    }
}

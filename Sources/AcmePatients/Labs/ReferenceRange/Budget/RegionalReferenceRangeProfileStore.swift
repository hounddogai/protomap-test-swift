import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional reference range profiles by code.
    protocol RegionalReferenceRangeProfileStore {
        func find(_ code: String) -> RegionalReferenceRangeProfile?
        func save(_ item: RegionalReferenceRangeProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalReferenceRangeProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalReferenceRangeProfileStore: RegionalReferenceRangeProfileStore {
        var items: [String: RegionalReferenceRangeProfile]
        var order: [String]

        init(items: [String: RegionalReferenceRangeProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalReferenceRangeProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalReferenceRangeProfile) {
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

        func list() -> [RegionalReferenceRangeProfile] {
            var out: [RegionalReferenceRangeProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalReferenceRangeProfileStore() -> any RegionalReferenceRangeProfileStore {
        return MemoryRegionalReferenceRangeProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalReferenceRangeProfileStore: RegionalReferenceRangeProfileStore {
        var inner: MemoryRegionalReferenceRangeProfileStore
        var cache: TTLCache<RegionalReferenceRangeProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalReferenceRangeProfileStore, cache: TTLCache<RegionalReferenceRangeProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalReferenceRangeProfile? {
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

        func save(_ item: RegionalReferenceRangeProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalReferenceRangeProfile] {
            return inner.list()
        }
    }

    static func newCachedRegionalReferenceRangeProfileStore(_ inner: MemoryRegionalReferenceRangeProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalReferenceRangeProfileStore {
        return CachedRegionalReferenceRangeProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional reference range profiles. Empty fields match all.
    final class RegionalReferenceRangeProfileQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalReferenceRangeProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalReferenceRangeProfile]) -> [RegionalReferenceRangeProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalReferenceRangeProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalReferenceRangeProfiles(_ store: any RegionalReferenceRangeProfileStore, query: RegionalReferenceRangeProfileQuery) -> [RegionalReferenceRangeProfile] {
        return query.apply(store.list())
    }
}

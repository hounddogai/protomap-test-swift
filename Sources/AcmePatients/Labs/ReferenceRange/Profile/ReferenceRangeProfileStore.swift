import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range profiles by code.
    protocol ReferenceRangeProfileStore {
        func find(_ code: String) -> ReferenceRangeProfile?
        func save(_ item: ReferenceRangeProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeProfileStore: ReferenceRangeProfileStore {
        var items: [String: ReferenceRangeProfile]
        var order: [String]

        init(items: [String: ReferenceRangeProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeProfile) {
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

        func list() -> [ReferenceRangeProfile] {
            var out: [ReferenceRangeProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeProfileStore() -> any ReferenceRangeProfileStore {
        return MemoryReferenceRangeProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeProfileStore: ReferenceRangeProfileStore {
        var inner: MemoryReferenceRangeProfileStore
        var cache: TTLCache<ReferenceRangeProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeProfileStore, cache: TTLCache<ReferenceRangeProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeProfile? {
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

        func save(_ item: ReferenceRangeProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeProfile] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeProfileStore(_ inner: MemoryReferenceRangeProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeProfileStore {
        return CachedReferenceRangeProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range profiles. Empty fields match all.
    final class ReferenceRangeProfileQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeProfile]) -> [ReferenceRangeProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeProfiles(_ store: any ReferenceRangeProfileStore, query: ReferenceRangeProfileQuery) -> [ReferenceRangeProfile] {
        return query.apply(store.list())
    }
}

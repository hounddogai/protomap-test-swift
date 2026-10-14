import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding profiles by code.
    protocol RoundingProfileStore {
        func find(_ code: String) -> RoundingProfile?
        func save(_ item: RoundingProfile)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingProfileStore: RoundingProfileStore {
        var items: [String: RoundingProfile]
        var order: [String]

        init(items: [String: RoundingProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingProfile) {
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

        func list() -> [RoundingProfile] {
            var out: [RoundingProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingProfileStore() -> any RoundingProfileStore {
        return MemoryRoundingProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingProfileStore: RoundingProfileStore {
        var inner: MemoryRoundingProfileStore
        var cache: TTLCache<RoundingProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingProfileStore, cache: TTLCache<RoundingProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingProfile? {
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

        func save(_ item: RoundingProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingProfile] {
            return inner.list()
        }
    }

    static func newCachedRoundingProfileStore(_ inner: MemoryRoundingProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingProfileStore {
        return CachedRoundingProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding profiles. Empty fields match all.
    final class RoundingProfileQuery {
        var channel: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingProfile) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingProfile]) -> [RoundingProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingProfiles(_ store: any RoundingProfileStore, query: RoundingProfileQuery) -> [RoundingProfile] {
        return query.apply(store.list())
    }
}

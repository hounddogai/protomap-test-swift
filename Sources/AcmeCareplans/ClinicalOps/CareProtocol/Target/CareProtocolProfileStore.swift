import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol profiles by code.
    protocol CareProtocolProfileStore {
        func find(_ code: String) -> CareProtocolProfile?
        func save(_ item: CareProtocolProfile)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolProfileStore: CareProtocolProfileStore {
        var items: [String: CareProtocolProfile]
        var order: [String]

        init(items: [String: CareProtocolProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolProfile) {
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

        func list() -> [CareProtocolProfile] {
            var out: [CareProtocolProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolProfileStore() -> any CareProtocolProfileStore {
        return MemoryCareProtocolProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolProfileStore: CareProtocolProfileStore {
        var inner: MemoryCareProtocolProfileStore
        var cache: TTLCache<CareProtocolProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolProfileStore, cache: TTLCache<CareProtocolProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolProfile? {
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

        func save(_ item: CareProtocolProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolProfile] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolProfileStore(_ inner: MemoryCareProtocolProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolProfileStore {
        return CachedCareProtocolProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol profiles. Empty fields match all.
    final class CareProtocolProfileQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolProfile) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolProfile]) -> [CareProtocolProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolProfiles(_ store: any CareProtocolProfileStore, query: CareProtocolProfileQuery) -> [CareProtocolProfile] {
        return query.apply(store.list())
    }
}

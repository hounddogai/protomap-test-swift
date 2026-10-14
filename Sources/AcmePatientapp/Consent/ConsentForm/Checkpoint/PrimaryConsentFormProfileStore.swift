import AcmePlatform
import Foundation

extension Consent {
    /// Keeps primary consent form profiles by code.
    protocol PrimaryConsentFormProfileStore {
        func find(_ code: String) -> PrimaryConsentFormProfile?
        func save(_ item: PrimaryConsentFormProfile)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryConsentFormProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryConsentFormProfileStore: PrimaryConsentFormProfileStore {
        var items: [String: PrimaryConsentFormProfile]
        var order: [String]

        init(items: [String: PrimaryConsentFormProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryConsentFormProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryConsentFormProfile) {
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

        func list() -> [PrimaryConsentFormProfile] {
            var out: [PrimaryConsentFormProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryConsentFormProfileStore() -> any PrimaryConsentFormProfileStore {
        return MemoryPrimaryConsentFormProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryConsentFormProfileStore: PrimaryConsentFormProfileStore {
        var inner: MemoryPrimaryConsentFormProfileStore
        var cache: TTLCache<PrimaryConsentFormProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryConsentFormProfileStore, cache: TTLCache<PrimaryConsentFormProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryConsentFormProfile? {
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

        func save(_ item: PrimaryConsentFormProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryConsentFormProfile] {
            return inner.list()
        }
    }

    static func newCachedPrimaryConsentFormProfileStore(_ inner: MemoryPrimaryConsentFormProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryConsentFormProfileStore {
        return CachedPrimaryConsentFormProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary consent form profiles. Empty fields match all.
    final class PrimaryConsentFormProfileQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryConsentFormProfile) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryConsentFormProfile]) -> [PrimaryConsentFormProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryConsentFormProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryConsentFormProfiles(_ store: any PrimaryConsentFormProfileStore, query: PrimaryConsentFormProfileQuery) -> [PrimaryConsentFormProfile] {
        return query.apply(store.list())
    }
}

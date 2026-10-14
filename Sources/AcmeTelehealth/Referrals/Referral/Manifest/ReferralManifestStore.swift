import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral manifests by code.
    protocol ReferralManifestStore {
        func find(_ code: String) -> ReferralManifest?
        func save(_ item: ReferralManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralManifestStore: ReferralManifestStore {
        var items: [String: ReferralManifest]
        var order: [String]

        init(items: [String: ReferralManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralManifest) {
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

        func list() -> [ReferralManifest] {
            var out: [ReferralManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralManifestStore() -> any ReferralManifestStore {
        return MemoryReferralManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralManifestStore: ReferralManifestStore {
        var inner: MemoryReferralManifestStore
        var cache: TTLCache<ReferralManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralManifestStore, cache: TTLCache<ReferralManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralManifest? {
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

        func save(_ item: ReferralManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralManifest] {
            return inner.list()
        }
    }

    static func newCachedReferralManifestStore(_ inner: MemoryReferralManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralManifestStore {
        return CachedReferralManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral manifests. Empty fields match all.
    final class ReferralManifestQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralManifest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralManifest]) -> [ReferralManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralManifests(_ store: any ReferralManifestStore, query: ReferralManifestQuery) -> [ReferralManifest] {
        return query.apply(store.list())
    }
}

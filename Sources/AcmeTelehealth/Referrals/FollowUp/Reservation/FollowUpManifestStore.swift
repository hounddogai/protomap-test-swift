import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up manifests by code.
    protocol FollowUpManifestStore {
        func find(_ code: String) -> FollowUpManifest?
        func save(_ item: FollowUpManifest)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpManifestStore: FollowUpManifestStore {
        var items: [String: FollowUpManifest]
        var order: [String]

        init(items: [String: FollowUpManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpManifest) {
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

        func list() -> [FollowUpManifest] {
            var out: [FollowUpManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpManifestStore() -> any FollowUpManifestStore {
        return MemoryFollowUpManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpManifestStore: FollowUpManifestStore {
        var inner: MemoryFollowUpManifestStore
        var cache: TTLCache<FollowUpManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpManifestStore, cache: TTLCache<FollowUpManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpManifest? {
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

        func save(_ item: FollowUpManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpManifest] {
            return inner.list()
        }
    }

    static func newCachedFollowUpManifestStore(_ inner: MemoryFollowUpManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpManifestStore {
        return CachedFollowUpManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up manifests. Empty fields match all.
    final class FollowUpManifestQuery {
        var locale: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minCost: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpManifest) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpManifest]) -> [FollowUpManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpManifests(_ store: any FollowUpManifestStore, query: FollowUpManifestQuery) -> [FollowUpManifest] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered follow up manifests by code.
    protocol TieredFollowUpManifestStore {
        func find(_ code: String) -> TieredFollowUpManifest?
        func save(_ item: TieredFollowUpManifest)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFollowUpManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFollowUpManifestStore: TieredFollowUpManifestStore {
        var items: [String: TieredFollowUpManifest]
        var order: [String]

        init(items: [String: TieredFollowUpManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFollowUpManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFollowUpManifest) {
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

        func list() -> [TieredFollowUpManifest] {
            var out: [TieredFollowUpManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFollowUpManifestStore() -> any TieredFollowUpManifestStore {
        return MemoryTieredFollowUpManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFollowUpManifestStore: TieredFollowUpManifestStore {
        var inner: MemoryTieredFollowUpManifestStore
        var cache: TTLCache<TieredFollowUpManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFollowUpManifestStore, cache: TTLCache<TieredFollowUpManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFollowUpManifest? {
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

        func save(_ item: TieredFollowUpManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFollowUpManifest] {
            return inner.list()
        }
    }

    static func newCachedTieredFollowUpManifestStore(_ inner: MemoryTieredFollowUpManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFollowUpManifestStore {
        return CachedTieredFollowUpManifestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered follow up manifests. Empty fields match all.
    final class TieredFollowUpManifestQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFollowUpManifest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredFollowUpManifest]) -> [TieredFollowUpManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFollowUpManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFollowUpManifests(_ store: any TieredFollowUpManifestStore, query: TieredFollowUpManifestQuery) -> [TieredFollowUpManifest] {
        return query.apply(store.list())
    }
}

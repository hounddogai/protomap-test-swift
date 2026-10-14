import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility manifests by code.
    protocol EligibilityManifestStore {
        func find(_ code: String) -> EligibilityManifest?
        func save(_ item: EligibilityManifest)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityManifestStore: EligibilityManifestStore {
        var items: [String: EligibilityManifest]
        var order: [String]

        init(items: [String: EligibilityManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityManifest) {
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

        func list() -> [EligibilityManifest] {
            var out: [EligibilityManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityManifestStore() -> any EligibilityManifestStore {
        return MemoryEligibilityManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityManifestStore: EligibilityManifestStore {
        var inner: MemoryEligibilityManifestStore
        var cache: TTLCache<EligibilityManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityManifestStore, cache: TTLCache<EligibilityManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityManifest? {
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

        func save(_ item: EligibilityManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityManifest] {
            return inner.list()
        }
    }

    static func newCachedEligibilityManifestStore(_ inner: MemoryEligibilityManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityManifestStore {
        return CachedEligibilityManifestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility manifests. Empty fields match all.
    final class EligibilityManifestQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityManifest]) -> [EligibilityManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityManifests(_ store: any EligibilityManifestStore, query: EligibilityManifestQuery) -> [EligibilityManifest] {
        return query.apply(store.list())
    }
}

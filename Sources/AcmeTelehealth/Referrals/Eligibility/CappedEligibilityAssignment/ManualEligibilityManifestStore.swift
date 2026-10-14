import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps manual eligibility manifests by code.
    protocol ManualEligibilityManifestStore {
        func find(_ code: String) -> ManualEligibilityManifest?
        func save(_ item: ManualEligibilityManifest)
        func remove(_ code: String) -> Bool
        func list() -> [ManualEligibilityManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualEligibilityManifestStore: ManualEligibilityManifestStore {
        var items: [String: ManualEligibilityManifest]
        var order: [String]

        init(items: [String: ManualEligibilityManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualEligibilityManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualEligibilityManifest) {
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

        func list() -> [ManualEligibilityManifest] {
            var out: [ManualEligibilityManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualEligibilityManifestStore() -> any ManualEligibilityManifestStore {
        return MemoryManualEligibilityManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualEligibilityManifestStore: ManualEligibilityManifestStore {
        var inner: MemoryManualEligibilityManifestStore
        var cache: TTLCache<ManualEligibilityManifest>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualEligibilityManifestStore, cache: TTLCache<ManualEligibilityManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualEligibilityManifest? {
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

        func save(_ item: ManualEligibilityManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualEligibilityManifest] {
            return inner.list()
        }
    }

    static func newCachedManualEligibilityManifestStore(_ inner: MemoryManualEligibilityManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualEligibilityManifestStore {
        return CachedManualEligibilityManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual eligibility manifests. Empty fields match all.
    final class ManualEligibilityManifestQuery {
        var ward: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualEligibilityManifest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ManualEligibilityManifest]) -> [ManualEligibilityManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualEligibilityManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualEligibilityManifests(_ store: any ManualEligibilityManifestStore, query: ManualEligibilityManifestQuery) -> [ManualEligibilityManifest] {
        return query.apply(store.list())
    }
}

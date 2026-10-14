import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution manifests by code.
    protocol SubstitutionManifestStore {
        func find(_ code: String) -> SubstitutionManifest?
        func save(_ item: SubstitutionManifest)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionManifest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionManifestStore: SubstitutionManifestStore {
        var items: [String: SubstitutionManifest]
        var order: [String]

        init(items: [String: SubstitutionManifest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionManifest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionManifest) {
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

        func list() -> [SubstitutionManifest] {
            var out: [SubstitutionManifest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionManifestStore() -> any SubstitutionManifestStore {
        return MemorySubstitutionManifestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionManifestStore: SubstitutionManifestStore {
        var inner: MemorySubstitutionManifestStore
        var cache: TTLCache<SubstitutionManifest>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionManifestStore, cache: TTLCache<SubstitutionManifest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionManifest? {
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

        func save(_ item: SubstitutionManifest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionManifest] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionManifestStore(_ inner: MemorySubstitutionManifestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionManifestStore {
        return CachedSubstitutionManifestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution manifests. Empty fields match all.
    final class SubstitutionManifestQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionManifest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionManifest]) -> [SubstitutionManifest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionManifest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionManifests(_ store: any SubstitutionManifestStore, query: SubstitutionManifestQuery) -> [SubstitutionManifest] {
        return query.apply(store.list())
    }
}

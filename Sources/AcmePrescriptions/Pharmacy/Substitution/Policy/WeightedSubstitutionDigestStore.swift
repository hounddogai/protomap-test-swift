import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted substitution digests by code.
    protocol WeightedSubstitutionDigestStore {
        func find(_ code: String) -> WeightedSubstitutionDigest?
        func save(_ item: WeightedSubstitutionDigest)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSubstitutionDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSubstitutionDigestStore: WeightedSubstitutionDigestStore {
        var items: [String: WeightedSubstitutionDigest]
        var order: [String]

        init(items: [String: WeightedSubstitutionDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSubstitutionDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSubstitutionDigest) {
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

        func list() -> [WeightedSubstitutionDigest] {
            var out: [WeightedSubstitutionDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSubstitutionDigestStore() -> any WeightedSubstitutionDigestStore {
        return MemoryWeightedSubstitutionDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSubstitutionDigestStore: WeightedSubstitutionDigestStore {
        var inner: MemoryWeightedSubstitutionDigestStore
        var cache: TTLCache<WeightedSubstitutionDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSubstitutionDigestStore, cache: TTLCache<WeightedSubstitutionDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSubstitutionDigest? {
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

        func save(_ item: WeightedSubstitutionDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSubstitutionDigest] {
            return inner.list()
        }
    }

    static func newCachedWeightedSubstitutionDigestStore(_ inner: MemoryWeightedSubstitutionDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSubstitutionDigestStore {
        return CachedWeightedSubstitutionDigestStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted substitution digests. Empty fields match all.
    final class WeightedSubstitutionDigestQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSubstitutionDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedSubstitutionDigest]) -> [WeightedSubstitutionDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSubstitutionDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSubstitutionDigests(_ store: any WeightedSubstitutionDigestStore, query: WeightedSubstitutionDigestQuery) -> [WeightedSubstitutionDigest] {
        return query.apply(store.list())
    }
}

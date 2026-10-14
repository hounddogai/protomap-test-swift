import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive formulary digests by code.
    protocol AdaptiveFormularyDigestStore {
        func find(_ code: String) -> AdaptiveFormularyDigest?
        func save(_ item: AdaptiveFormularyDigest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveFormularyDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveFormularyDigestStore: AdaptiveFormularyDigestStore {
        var items: [String: AdaptiveFormularyDigest]
        var order: [String]

        init(items: [String: AdaptiveFormularyDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveFormularyDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveFormularyDigest) {
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

        func list() -> [AdaptiveFormularyDigest] {
            var out: [AdaptiveFormularyDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveFormularyDigestStore() -> any AdaptiveFormularyDigestStore {
        return MemoryAdaptiveFormularyDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveFormularyDigestStore: AdaptiveFormularyDigestStore {
        var inner: MemoryAdaptiveFormularyDigestStore
        var cache: TTLCache<AdaptiveFormularyDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveFormularyDigestStore, cache: TTLCache<AdaptiveFormularyDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveFormularyDigest? {
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

        func save(_ item: AdaptiveFormularyDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveFormularyDigest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveFormularyDigestStore(_ inner: MemoryAdaptiveFormularyDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveFormularyDigestStore {
        return CachedAdaptiveFormularyDigestStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive formulary digests. Empty fields match all.
    final class AdaptiveFormularyDigestQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveFormularyDigest) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveFormularyDigest]) -> [AdaptiveFormularyDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveFormularyDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveFormularyDigests(_ store: any AdaptiveFormularyDigestStore, query: AdaptiveFormularyDigestQuery) -> [AdaptiveFormularyDigest] {
        return query.apply(store.list())
    }
}

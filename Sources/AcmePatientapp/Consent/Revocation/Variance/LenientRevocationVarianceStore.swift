import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient revocation variances by code.
    protocol LenientRevocationVarianceStore {
        func find(_ code: String) -> LenientRevocationVariance?
        func save(_ item: LenientRevocationVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientRevocationVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientRevocationVarianceStore: LenientRevocationVarianceStore {
        var items: [String: LenientRevocationVariance]
        var order: [String]

        init(items: [String: LenientRevocationVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientRevocationVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientRevocationVariance) {
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

        func list() -> [LenientRevocationVariance] {
            var out: [LenientRevocationVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientRevocationVarianceStore() -> any LenientRevocationVarianceStore {
        return MemoryLenientRevocationVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientRevocationVarianceStore: LenientRevocationVarianceStore {
        var inner: MemoryLenientRevocationVarianceStore
        var cache: TTLCache<LenientRevocationVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientRevocationVarianceStore, cache: TTLCache<LenientRevocationVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientRevocationVariance? {
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

        func save(_ item: LenientRevocationVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientRevocationVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientRevocationVarianceStore(_ inner: MemoryLenientRevocationVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientRevocationVarianceStore {
        return CachedLenientRevocationVarianceStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient revocation variances. Empty fields match all.
    final class LenientRevocationVarianceQuery {
        var source: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRevision: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientRevocationVariance) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientRevocationVariance]) -> [LenientRevocationVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientRevocationVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientRevocationVariances(_ store: any LenientRevocationVarianceStore, query: LenientRevocationVarianceQuery) -> [LenientRevocationVariance] {
        return query.apply(store.list())
    }
}

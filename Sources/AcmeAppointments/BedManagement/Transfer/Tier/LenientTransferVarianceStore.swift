import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient transfer variances by code.
    protocol LenientTransferVarianceStore {
        func find(_ code: String) -> LenientTransferVariance?
        func save(_ item: LenientTransferVariance)
        func remove(_ code: String) -> Bool
        func list() -> [LenientTransferVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientTransferVarianceStore: LenientTransferVarianceStore {
        var items: [String: LenientTransferVariance]
        var order: [String]

        init(items: [String: LenientTransferVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientTransferVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientTransferVariance) {
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

        func list() -> [LenientTransferVariance] {
            var out: [LenientTransferVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientTransferVarianceStore() -> any LenientTransferVarianceStore {
        return MemoryLenientTransferVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientTransferVarianceStore: LenientTransferVarianceStore {
        var inner: MemoryLenientTransferVarianceStore
        var cache: TTLCache<LenientTransferVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientTransferVarianceStore, cache: TTLCache<LenientTransferVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientTransferVariance? {
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

        func save(_ item: LenientTransferVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientTransferVariance] {
            return inner.list()
        }
    }

    static func newCachedLenientTransferVarianceStore(_ inner: MemoryLenientTransferVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientTransferVarianceStore {
        return CachedLenientTransferVarianceStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient transfer variances. Empty fields match all.
    final class LenientTransferVarianceQuery {
        var title: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientTransferVariance) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientTransferVariance]) -> [LenientTransferVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientTransferVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientTransferVariances(_ store: any LenientTransferVarianceStore, query: LenientTransferVarianceQuery) -> [LenientTransferVariance] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual recall claims by code.
    protocol ManualRecallClaimStore {
        func find(_ code: String) -> ManualRecallClaim?
        func save(_ item: ManualRecallClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRecallClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRecallClaimStore: ManualRecallClaimStore {
        var items: [String: ManualRecallClaim]
        var order: [String]

        init(items: [String: ManualRecallClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRecallClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRecallClaim) {
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

        func list() -> [ManualRecallClaim] {
            var out: [ManualRecallClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRecallClaimStore() -> any ManualRecallClaimStore {
        return MemoryManualRecallClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRecallClaimStore: ManualRecallClaimStore {
        var inner: MemoryManualRecallClaimStore
        var cache: TTLCache<ManualRecallClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRecallClaimStore, cache: TTLCache<ManualRecallClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRecallClaim? {
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

        func save(_ item: ManualRecallClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRecallClaim] {
            return inner.list()
        }
    }

    static func newCachedManualRecallClaimStore(_ inner: MemoryManualRecallClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRecallClaimStore {
        return CachedManualRecallClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual recall claims. Empty fields match all.
    final class ManualRecallClaimQuery {
        var source: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRecallClaim) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRecallClaim]) -> [ManualRecallClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRecallClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRecallClaims(_ store: any ManualRecallClaimStore, query: ManualRecallClaimQuery) -> [ManualRecallClaim] {
        return query.apply(store.list())
    }
}

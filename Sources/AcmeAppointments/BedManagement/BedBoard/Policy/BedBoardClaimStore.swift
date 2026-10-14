import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board claims by code.
    protocol BedBoardClaimStore {
        func find(_ code: String) -> BedBoardClaim?
        func save(_ item: BedBoardClaim)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardClaimStore: BedBoardClaimStore {
        var items: [String: BedBoardClaim]
        var order: [String]

        init(items: [String: BedBoardClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardClaim) {
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

        func list() -> [BedBoardClaim] {
            var out: [BedBoardClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardClaimStore() -> any BedBoardClaimStore {
        return MemoryBedBoardClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardClaimStore: BedBoardClaimStore {
        var inner: MemoryBedBoardClaimStore
        var cache: TTLCache<BedBoardClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardClaimStore, cache: TTLCache<BedBoardClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardClaim? {
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

        func save(_ item: BedBoardClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardClaim] {
            return inner.list()
        }
    }

    static func newCachedBedBoardClaimStore(_ inner: MemoryBedBoardClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardClaimStore {
        return CachedBedBoardClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board claims. Empty fields match all.
    final class BedBoardClaimQuery {
        var locale: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minAmount: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardClaim) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [BedBoardClaim]) -> [BedBoardClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardClaims(_ store: any BedBoardClaimStore, query: BedBoardClaimQuery) -> [BedBoardClaim] {
        return query.apply(store.list())
    }
}

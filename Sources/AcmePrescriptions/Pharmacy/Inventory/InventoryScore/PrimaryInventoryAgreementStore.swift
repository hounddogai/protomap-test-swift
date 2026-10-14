import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary inventory agreements by code.
    protocol PrimaryInventoryAgreementStore {
        func find(_ code: String) -> PrimaryInventoryAgreement?
        func save(_ item: PrimaryInventoryAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryInventoryAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryInventoryAgreementStore: PrimaryInventoryAgreementStore {
        var items: [String: PrimaryInventoryAgreement]
        var order: [String]

        init(items: [String: PrimaryInventoryAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryInventoryAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryInventoryAgreement) {
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

        func list() -> [PrimaryInventoryAgreement] {
            var out: [PrimaryInventoryAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryInventoryAgreementStore() -> any PrimaryInventoryAgreementStore {
        return MemoryPrimaryInventoryAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryInventoryAgreementStore: PrimaryInventoryAgreementStore {
        var inner: MemoryPrimaryInventoryAgreementStore
        var cache: TTLCache<PrimaryInventoryAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryInventoryAgreementStore, cache: TTLCache<PrimaryInventoryAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryInventoryAgreement? {
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

        func save(_ item: PrimaryInventoryAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryInventoryAgreement] {
            return inner.list()
        }
    }

    static func newCachedPrimaryInventoryAgreementStore(_ inner: MemoryPrimaryInventoryAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryInventoryAgreementStore {
        return CachedPrimaryInventoryAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary inventory agreements. Empty fields match all.
    final class PrimaryInventoryAgreementQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryInventoryAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryInventoryAgreement]) -> [PrimaryInventoryAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryInventoryAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryInventoryAgreements(_ store: any PrimaryInventoryAgreementStore, query: PrimaryInventoryAgreementQuery) -> [PrimaryInventoryAgreement] {
        return query.apply(store.list())
    }
}

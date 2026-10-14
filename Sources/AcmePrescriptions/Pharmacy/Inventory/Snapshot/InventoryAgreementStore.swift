import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory agreements by code.
    protocol InventoryAgreementStore {
        func find(_ code: String) -> InventoryAgreement?
        func save(_ item: InventoryAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryAgreementStore: InventoryAgreementStore {
        var items: [String: InventoryAgreement]
        var order: [String]

        init(items: [String: InventoryAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryAgreement) {
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

        func list() -> [InventoryAgreement] {
            var out: [InventoryAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryAgreementStore() -> any InventoryAgreementStore {
        return MemoryInventoryAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryAgreementStore: InventoryAgreementStore {
        var inner: MemoryInventoryAgreementStore
        var cache: TTLCache<InventoryAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryAgreementStore, cache: TTLCache<InventoryAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryAgreement? {
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

        func save(_ item: InventoryAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryAgreement] {
            return inner.list()
        }
    }

    static func newCachedInventoryAgreementStore(_ inner: MemoryInventoryAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryAgreementStore {
        return CachedInventoryAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory agreements. Empty fields match all.
    final class InventoryAgreementQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryAgreement) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryAgreement]) -> [InventoryAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryAgreements(_ store: any InventoryAgreementStore, query: InventoryAgreementQuery) -> [InventoryAgreement] {
        return query.apply(store.list())
    }
}

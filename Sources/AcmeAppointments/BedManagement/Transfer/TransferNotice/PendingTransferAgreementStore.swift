import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending transfer agreements by code.
    protocol PendingTransferAgreementStore {
        func find(_ code: String) -> PendingTransferAgreement?
        func save(_ item: PendingTransferAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PendingTransferAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingTransferAgreementStore: PendingTransferAgreementStore {
        var items: [String: PendingTransferAgreement]
        var order: [String]

        init(items: [String: PendingTransferAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingTransferAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingTransferAgreement) {
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

        func list() -> [PendingTransferAgreement] {
            var out: [PendingTransferAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingTransferAgreementStore() -> any PendingTransferAgreementStore {
        return MemoryPendingTransferAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingTransferAgreementStore: PendingTransferAgreementStore {
        var inner: MemoryPendingTransferAgreementStore
        var cache: TTLCache<PendingTransferAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingTransferAgreementStore, cache: TTLCache<PendingTransferAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingTransferAgreement? {
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

        func save(_ item: PendingTransferAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingTransferAgreement] {
            return inner.list()
        }
    }

    static func newCachedPendingTransferAgreementStore(_ inner: MemoryPendingTransferAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingTransferAgreementStore {
        return CachedPendingTransferAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending transfer agreements. Empty fields match all.
    final class PendingTransferAgreementQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingTransferAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingTransferAgreement]) -> [PendingTransferAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingTransferAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingTransferAgreements(_ store: any PendingTransferAgreementStore, query: PendingTransferAgreementQuery) -> [PendingTransferAgreement] {
        return query.apply(store.list())
    }
}

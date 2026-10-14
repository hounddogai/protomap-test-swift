import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps default transfer agreements by code.
    protocol DefaultTransferAgreementStore {
        func find(_ code: String) -> DefaultTransferAgreement?
        func save(_ item: DefaultTransferAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultTransferAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultTransferAgreementStore: DefaultTransferAgreementStore {
        var items: [String: DefaultTransferAgreement]
        var order: [String]

        init(items: [String: DefaultTransferAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultTransferAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultTransferAgreement) {
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

        func list() -> [DefaultTransferAgreement] {
            var out: [DefaultTransferAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultTransferAgreementStore() -> any DefaultTransferAgreementStore {
        return MemoryDefaultTransferAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultTransferAgreementStore: DefaultTransferAgreementStore {
        var inner: MemoryDefaultTransferAgreementStore
        var cache: TTLCache<DefaultTransferAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultTransferAgreementStore, cache: TTLCache<DefaultTransferAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultTransferAgreement? {
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

        func save(_ item: DefaultTransferAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultTransferAgreement] {
            return inner.list()
        }
    }

    static func newCachedDefaultTransferAgreementStore(_ inner: MemoryDefaultTransferAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultTransferAgreementStore {
        return CachedDefaultTransferAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default transfer agreements. Empty fields match all.
    final class DefaultTransferAgreementQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultTransferAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultTransferAgreement]) -> [DefaultTransferAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultTransferAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultTransferAgreements(_ store: any DefaultTransferAgreementStore, query: DefaultTransferAgreementQuery) -> [DefaultTransferAgreement] {
        return query.apply(store.list())
    }
}

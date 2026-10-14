import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional revocation agreements by code.
    protocol RegionalRevocationAgreementStore {
        func find(_ code: String) -> RegionalRevocationAgreement?
        func save(_ item: RegionalRevocationAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalRevocationAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalRevocationAgreementStore: RegionalRevocationAgreementStore {
        var items: [String: RegionalRevocationAgreement]
        var order: [String]

        init(items: [String: RegionalRevocationAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalRevocationAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalRevocationAgreement) {
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

        func list() -> [RegionalRevocationAgreement] {
            var out: [RegionalRevocationAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalRevocationAgreementStore() -> any RegionalRevocationAgreementStore {
        return MemoryRegionalRevocationAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalRevocationAgreementStore: RegionalRevocationAgreementStore {
        var inner: MemoryRegionalRevocationAgreementStore
        var cache: TTLCache<RegionalRevocationAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalRevocationAgreementStore, cache: TTLCache<RegionalRevocationAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalRevocationAgreement? {
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

        func save(_ item: RegionalRevocationAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalRevocationAgreement] {
            return inner.list()
        }
    }

    static func newCachedRegionalRevocationAgreementStore(_ inner: MemoryRegionalRevocationAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalRevocationAgreementStore {
        return CachedRegionalRevocationAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional revocation agreements. Empty fields match all.
    final class RegionalRevocationAgreementQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalRevocationAgreement) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [RegionalRevocationAgreement]) -> [RegionalRevocationAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalRevocationAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalRevocationAgreements(_ store: any RegionalRevocationAgreementStore, query: RegionalRevocationAgreementQuery) -> [RegionalRevocationAgreement] {
        return query.apply(store.list())
    }
}

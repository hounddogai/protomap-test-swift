import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal order set agreements by code.
    protocol SeasonalOrderSetAgreementStore {
        func find(_ code: String) -> SeasonalOrderSetAgreement?
        func save(_ item: SeasonalOrderSetAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalOrderSetAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalOrderSetAgreementStore: SeasonalOrderSetAgreementStore {
        var items: [String: SeasonalOrderSetAgreement]
        var order: [String]

        init(items: [String: SeasonalOrderSetAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalOrderSetAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalOrderSetAgreement) {
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

        func list() -> [SeasonalOrderSetAgreement] {
            var out: [SeasonalOrderSetAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalOrderSetAgreementStore() -> any SeasonalOrderSetAgreementStore {
        return MemorySeasonalOrderSetAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalOrderSetAgreementStore: SeasonalOrderSetAgreementStore {
        var inner: MemorySeasonalOrderSetAgreementStore
        var cache: TTLCache<SeasonalOrderSetAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalOrderSetAgreementStore, cache: TTLCache<SeasonalOrderSetAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalOrderSetAgreement? {
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

        func save(_ item: SeasonalOrderSetAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalOrderSetAgreement] {
            return inner.list()
        }
    }

    static func newCachedSeasonalOrderSetAgreementStore(_ inner: MemorySeasonalOrderSetAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalOrderSetAgreementStore {
        return CachedSeasonalOrderSetAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal order set agreements. Empty fields match all.
    final class SeasonalOrderSetAgreementQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalOrderSetAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalOrderSetAgreement]) -> [SeasonalOrderSetAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalOrderSetAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalOrderSetAgreements(_ store: any SeasonalOrderSetAgreementStore, query: SeasonalOrderSetAgreementQuery) -> [SeasonalOrderSetAgreement] {
        return query.apply(store.list())
    }
}

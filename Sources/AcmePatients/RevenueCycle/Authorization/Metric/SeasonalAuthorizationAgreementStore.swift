import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal authorization agreements by code.
    protocol SeasonalAuthorizationAgreementStore {
        func find(_ code: String) -> SeasonalAuthorizationAgreement?
        func save(_ item: SeasonalAuthorizationAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalAuthorizationAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalAuthorizationAgreementStore: SeasonalAuthorizationAgreementStore {
        var items: [String: SeasonalAuthorizationAgreement]
        var order: [String]

        init(items: [String: SeasonalAuthorizationAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalAuthorizationAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalAuthorizationAgreement) {
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

        func list() -> [SeasonalAuthorizationAgreement] {
            var out: [SeasonalAuthorizationAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalAuthorizationAgreementStore() -> any SeasonalAuthorizationAgreementStore {
        return MemorySeasonalAuthorizationAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalAuthorizationAgreementStore: SeasonalAuthorizationAgreementStore {
        var inner: MemorySeasonalAuthorizationAgreementStore
        var cache: TTLCache<SeasonalAuthorizationAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalAuthorizationAgreementStore, cache: TTLCache<SeasonalAuthorizationAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalAuthorizationAgreement? {
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

        func save(_ item: SeasonalAuthorizationAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalAuthorizationAgreement] {
            return inner.list()
        }
    }

    static func newCachedSeasonalAuthorizationAgreementStore(_ inner: MemorySeasonalAuthorizationAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalAuthorizationAgreementStore {
        return CachedSeasonalAuthorizationAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal authorization agreements. Empty fields match all.
    final class SeasonalAuthorizationAgreementQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalAuthorizationAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [SeasonalAuthorizationAgreement]) -> [SeasonalAuthorizationAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalAuthorizationAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalAuthorizationAgreements(_ store: any SeasonalAuthorizationAgreementStore, query: SeasonalAuthorizationAgreementQuery) -> [SeasonalAuthorizationAgreement] {
        return query.apply(store.list())
    }
}

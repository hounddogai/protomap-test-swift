import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal statement agreements by code.
    protocol SeasonalStatementAgreementStore {
        func find(_ code: String) -> SeasonalStatementAgreement?
        func save(_ item: SeasonalStatementAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalStatementAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalStatementAgreementStore: SeasonalStatementAgreementStore {
        var items: [String: SeasonalStatementAgreement]
        var order: [String]

        init(items: [String: SeasonalStatementAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalStatementAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalStatementAgreement) {
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

        func list() -> [SeasonalStatementAgreement] {
            var out: [SeasonalStatementAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalStatementAgreementStore() -> any SeasonalStatementAgreementStore {
        return MemorySeasonalStatementAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalStatementAgreementStore: SeasonalStatementAgreementStore {
        var inner: MemorySeasonalStatementAgreementStore
        var cache: TTLCache<SeasonalStatementAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalStatementAgreementStore, cache: TTLCache<SeasonalStatementAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalStatementAgreement? {
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

        func save(_ item: SeasonalStatementAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalStatementAgreement] {
            return inner.list()
        }
    }

    static func newCachedSeasonalStatementAgreementStore(_ inner: MemorySeasonalStatementAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalStatementAgreementStore {
        return CachedSeasonalStatementAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal statement agreements. Empty fields match all.
    final class SeasonalStatementAgreementQuery {
        var segment: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalStatementAgreement) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalStatementAgreement]) -> [SeasonalStatementAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalStatementAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalStatementAgreements(_ store: any SeasonalStatementAgreementStore, query: SeasonalStatementAgreementQuery) -> [SeasonalStatementAgreement] {
        return query.apply(store.list())
    }
}

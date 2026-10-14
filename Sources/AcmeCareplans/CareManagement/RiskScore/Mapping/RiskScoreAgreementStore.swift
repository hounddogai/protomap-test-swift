import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score agreements by code.
    protocol RiskScoreAgreementStore {
        func find(_ code: String) -> RiskScoreAgreement?
        func save(_ item: RiskScoreAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreAgreementStore: RiskScoreAgreementStore {
        var items: [String: RiskScoreAgreement]
        var order: [String]

        init(items: [String: RiskScoreAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreAgreement) {
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

        func list() -> [RiskScoreAgreement] {
            var out: [RiskScoreAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreAgreementStore() -> any RiskScoreAgreementStore {
        return MemoryRiskScoreAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreAgreementStore: RiskScoreAgreementStore {
        var inner: MemoryRiskScoreAgreementStore
        var cache: TTLCache<RiskScoreAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreAgreementStore, cache: TTLCache<RiskScoreAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreAgreement? {
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

        func save(_ item: RiskScoreAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreAgreement] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreAgreementStore(_ inner: MemoryRiskScoreAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreAgreementStore {
        return CachedRiskScoreAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score agreements. Empty fields match all.
    final class RiskScoreAgreementQuery {
        var country: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreAgreement]) -> [RiskScoreAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreAgreements(_ store: any RiskScoreAgreementStore, query: RiskScoreAgreementQuery) -> [RiskScoreAgreement] {
        return query.apply(store.list())
    }
}

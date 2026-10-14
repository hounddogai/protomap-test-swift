import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending statement agreements by code.
    protocol PendingStatementAgreementStore {
        func find(_ code: String) -> PendingStatementAgreement?
        func save(_ item: PendingStatementAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [PendingStatementAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingStatementAgreementStore: PendingStatementAgreementStore {
        var items: [String: PendingStatementAgreement]
        var order: [String]

        init(items: [String: PendingStatementAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingStatementAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingStatementAgreement) {
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

        func list() -> [PendingStatementAgreement] {
            var out: [PendingStatementAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingStatementAgreementStore() -> any PendingStatementAgreementStore {
        return MemoryPendingStatementAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingStatementAgreementStore: PendingStatementAgreementStore {
        var inner: MemoryPendingStatementAgreementStore
        var cache: TTLCache<PendingStatementAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingStatementAgreementStore, cache: TTLCache<PendingStatementAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingStatementAgreement? {
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

        func save(_ item: PendingStatementAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingStatementAgreement] {
            return inner.list()
        }
    }

    static func newCachedPendingStatementAgreementStore(_ inner: MemoryPendingStatementAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingStatementAgreementStore {
        return CachedPendingStatementAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending statement agreements. Empty fields match all.
    final class PendingStatementAgreementQuery {
        var region: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCopay: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingStatementAgreement) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingStatementAgreement]) -> [PendingStatementAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingStatementAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingStatementAgreements(_ store: any PendingStatementAgreementStore, query: PendingStatementAgreementQuery) -> [PendingStatementAgreement] {
        return query.apply(store.list())
    }
}

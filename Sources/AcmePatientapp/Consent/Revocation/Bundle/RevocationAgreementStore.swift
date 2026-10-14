import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation agreements by code.
    protocol RevocationAgreementStore {
        func find(_ code: String) -> RevocationAgreement?
        func save(_ item: RevocationAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationAgreementStore: RevocationAgreementStore {
        var items: [String: RevocationAgreement]
        var order: [String]

        init(items: [String: RevocationAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationAgreement) {
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

        func list() -> [RevocationAgreement] {
            var out: [RevocationAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationAgreementStore() -> any RevocationAgreementStore {
        return MemoryRevocationAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationAgreementStore: RevocationAgreementStore {
        var inner: MemoryRevocationAgreementStore
        var cache: TTLCache<RevocationAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationAgreementStore, cache: TTLCache<RevocationAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationAgreement? {
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

        func save(_ item: RevocationAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationAgreement] {
            return inner.list()
        }
    }

    static func newCachedRevocationAgreementStore(_ inner: MemoryRevocationAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationAgreementStore {
        return CachedRevocationAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation agreements. Empty fields match all.
    final class RevocationAgreementQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationAgreement]) -> [RevocationAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationAgreements(_ store: any RevocationAgreementStore, query: RevocationAgreementQuery) -> [RevocationAgreement] {
        return query.apply(store.list())
    }
}

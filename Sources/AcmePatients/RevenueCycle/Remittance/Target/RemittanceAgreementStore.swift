import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance agreements by code.
    protocol RemittanceAgreementStore {
        func find(_ code: String) -> RemittanceAgreement?
        func save(_ item: RemittanceAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceAgreementStore: RemittanceAgreementStore {
        var items: [String: RemittanceAgreement]
        var order: [String]

        init(items: [String: RemittanceAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceAgreement) {
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

        func list() -> [RemittanceAgreement] {
            var out: [RemittanceAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceAgreementStore() -> any RemittanceAgreementStore {
        return MemoryRemittanceAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceAgreementStore: RemittanceAgreementStore {
        var inner: MemoryRemittanceAgreementStore
        var cache: TTLCache<RemittanceAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceAgreementStore, cache: TTLCache<RemittanceAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceAgreement? {
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

        func save(_ item: RemittanceAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceAgreement] {
            return inner.list()
        }
    }

    static func newCachedRemittanceAgreementStore(_ inner: MemoryRemittanceAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceAgreementStore {
        return CachedRemittanceAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance agreements. Empty fields match all.
    final class RemittanceAgreementQuery {
        var segment: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minSequence: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceAgreement) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceAgreement]) -> [RemittanceAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceAgreements(_ store: any RemittanceAgreementStore, query: RemittanceAgreementQuery) -> [RemittanceAgreement] {
        return query.apply(store.list())
    }
}

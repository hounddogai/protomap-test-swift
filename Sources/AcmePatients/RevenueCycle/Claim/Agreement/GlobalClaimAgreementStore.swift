import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global claim agreements by code.
    protocol GlobalClaimAgreementStore {
        func find(_ code: String) -> GlobalClaimAgreement?
        func save(_ item: GlobalClaimAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalClaimAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalClaimAgreementStore: GlobalClaimAgreementStore {
        var items: [String: GlobalClaimAgreement]
        var order: [String]

        init(items: [String: GlobalClaimAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalClaimAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalClaimAgreement) {
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

        func list() -> [GlobalClaimAgreement] {
            var out: [GlobalClaimAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalClaimAgreementStore() -> any GlobalClaimAgreementStore {
        return MemoryGlobalClaimAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalClaimAgreementStore: GlobalClaimAgreementStore {
        var inner: MemoryGlobalClaimAgreementStore
        var cache: TTLCache<GlobalClaimAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalClaimAgreementStore, cache: TTLCache<GlobalClaimAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalClaimAgreement? {
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

        func save(_ item: GlobalClaimAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalClaimAgreement] {
            return inner.list()
        }
    }

    static func newCachedGlobalClaimAgreementStore(_ inner: MemoryGlobalClaimAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalClaimAgreementStore {
        return CachedGlobalClaimAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global claim agreements. Empty fields match all.
    final class GlobalClaimAgreementQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalClaimAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalClaimAgreement]) -> [GlobalClaimAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalClaimAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalClaimAgreements(_ store: any GlobalClaimAgreementStore, query: GlobalClaimAgreementQuery) -> [GlobalClaimAgreement] {
        return query.apply(store.list())
    }
}

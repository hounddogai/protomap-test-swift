import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped cleaning agreements by code.
    protocol CappedCleaningAgreementStore {
        func find(_ code: String) -> CappedCleaningAgreement?
        func save(_ item: CappedCleaningAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [CappedCleaningAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedCleaningAgreementStore: CappedCleaningAgreementStore {
        var items: [String: CappedCleaningAgreement]
        var order: [String]

        init(items: [String: CappedCleaningAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedCleaningAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedCleaningAgreement) {
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

        func list() -> [CappedCleaningAgreement] {
            var out: [CappedCleaningAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedCleaningAgreementStore() -> any CappedCleaningAgreementStore {
        return MemoryCappedCleaningAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedCleaningAgreementStore: CappedCleaningAgreementStore {
        var inner: MemoryCappedCleaningAgreementStore
        var cache: TTLCache<CappedCleaningAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedCleaningAgreementStore, cache: TTLCache<CappedCleaningAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedCleaningAgreement? {
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

        func save(_ item: CappedCleaningAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedCleaningAgreement] {
            return inner.list()
        }
    }

    static func newCachedCappedCleaningAgreementStore(_ inner: MemoryCappedCleaningAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedCleaningAgreementStore {
        return CachedCappedCleaningAgreementStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped cleaning agreements. Empty fields match all.
    final class CappedCleaningAgreementQuery {
        var category: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedCleaningAgreement) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [CappedCleaningAgreement]) -> [CappedCleaningAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedCleaningAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedCleaningAgreements(_ store: any CappedCleaningAgreementStore, query: CappedCleaningAgreementQuery) -> [CappedCleaningAgreement] {
        return query.apply(store.list())
    }
}

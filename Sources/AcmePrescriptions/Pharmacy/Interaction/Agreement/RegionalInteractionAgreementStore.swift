import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional interaction agreements by code.
    protocol RegionalInteractionAgreementStore {
        func find(_ code: String) -> RegionalInteractionAgreement?
        func save(_ item: RegionalInteractionAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalInteractionAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalInteractionAgreementStore: RegionalInteractionAgreementStore {
        var items: [String: RegionalInteractionAgreement]
        var order: [String]

        init(items: [String: RegionalInteractionAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalInteractionAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalInteractionAgreement) {
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

        func list() -> [RegionalInteractionAgreement] {
            var out: [RegionalInteractionAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalInteractionAgreementStore() -> any RegionalInteractionAgreementStore {
        return MemoryRegionalInteractionAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalInteractionAgreementStore: RegionalInteractionAgreementStore {
        var inner: MemoryRegionalInteractionAgreementStore
        var cache: TTLCache<RegionalInteractionAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalInteractionAgreementStore, cache: TTLCache<RegionalInteractionAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalInteractionAgreement? {
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

        func save(_ item: RegionalInteractionAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalInteractionAgreement] {
            return inner.list()
        }
    }

    static func newCachedRegionalInteractionAgreementStore(_ inner: MemoryRegionalInteractionAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalInteractionAgreementStore {
        return CachedRegionalInteractionAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional interaction agreements. Empty fields match all.
    final class RegionalInteractionAgreementQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalInteractionAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalInteractionAgreement]) -> [RegionalInteractionAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalInteractionAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalInteractionAgreements(_ store: any RegionalInteractionAgreementStore, query: RegionalInteractionAgreementQuery) -> [RegionalInteractionAgreement] {
        return query.apply(store.list())
    }
}

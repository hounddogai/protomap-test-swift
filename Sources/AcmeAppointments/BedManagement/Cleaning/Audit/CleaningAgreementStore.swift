import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning agreements by code.
    protocol CleaningAgreementStore {
        func find(_ code: String) -> CleaningAgreement?
        func save(_ item: CleaningAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningAgreementStore: CleaningAgreementStore {
        var items: [String: CleaningAgreement]
        var order: [String]

        init(items: [String: CleaningAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningAgreement) {
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

        func list() -> [CleaningAgreement] {
            var out: [CleaningAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningAgreementStore() -> any CleaningAgreementStore {
        return MemoryCleaningAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningAgreementStore: CleaningAgreementStore {
        var inner: MemoryCleaningAgreementStore
        var cache: TTLCache<CleaningAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningAgreementStore, cache: TTLCache<CleaningAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningAgreement? {
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

        func save(_ item: CleaningAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningAgreement] {
            return inner.list()
        }
    }

    static func newCachedCleaningAgreementStore(_ inner: MemoryCleaningAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningAgreementStore {
        return CachedCleaningAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning agreements. Empty fields match all.
    final class CleaningAgreementQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningAgreement]) -> [CleaningAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningAgreements(_ store: any CleaningAgreementStore, query: CleaningAgreementQuery) -> [CleaningAgreement] {
        return query.apply(store.list())
    }
}

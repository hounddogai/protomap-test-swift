import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure agreements by code.
    protocol DisclosureAgreementStore {
        func find(_ code: String) -> DisclosureAgreement?
        func save(_ item: DisclosureAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureAgreementStore: DisclosureAgreementStore {
        var items: [String: DisclosureAgreement]
        var order: [String]

        init(items: [String: DisclosureAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureAgreement) {
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

        func list() -> [DisclosureAgreement] {
            var out: [DisclosureAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureAgreementStore() -> any DisclosureAgreementStore {
        return MemoryDisclosureAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureAgreementStore: DisclosureAgreementStore {
        var inner: MemoryDisclosureAgreementStore
        var cache: TTLCache<DisclosureAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureAgreementStore, cache: TTLCache<DisclosureAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureAgreement? {
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

        func save(_ item: DisclosureAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureAgreement] {
            return inner.list()
        }
    }

    static func newCachedDisclosureAgreementStore(_ inner: MemoryDisclosureAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureAgreementStore {
        return CachedDisclosureAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure agreements. Empty fields match all.
    final class DisclosureAgreementQuery {
        var locale: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureAgreement) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [DisclosureAgreement]) -> [DisclosureAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureAgreements(_ store: any DisclosureAgreementStore, query: DisclosureAgreementQuery) -> [DisclosureAgreement] {
        return query.apply(store.list())
    }
}

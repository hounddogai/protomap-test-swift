import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language agreements by code.
    protocol LanguageAgreementStore {
        func find(_ code: String) -> LanguageAgreement?
        func save(_ item: LanguageAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageAgreementStore: LanguageAgreementStore {
        var items: [String: LanguageAgreement]
        var order: [String]

        init(items: [String: LanguageAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageAgreement) {
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

        func list() -> [LanguageAgreement] {
            var out: [LanguageAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageAgreementStore() -> any LanguageAgreementStore {
        return MemoryLanguageAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageAgreementStore: LanguageAgreementStore {
        var inner: MemoryLanguageAgreementStore
        var cache: TTLCache<LanguageAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageAgreementStore, cache: TTLCache<LanguageAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageAgreement? {
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

        func save(_ item: LanguageAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageAgreement] {
            return inner.list()
        }
    }

    static func newCachedLanguageAgreementStore(_ inner: MemoryLanguageAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageAgreementStore {
        return CachedLanguageAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language agreements. Empty fields match all.
    final class LanguageAgreementQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageAgreement) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageAgreement]) -> [LanguageAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageAgreements(_ store: any LanguageAgreementStore, query: LanguageAgreementQuery) -> [LanguageAgreement] {
        return query.apply(store.list())
    }
}

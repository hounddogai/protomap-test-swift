import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language policies by code.
    protocol LanguagePolicyStore {
        func find(_ code: String) -> LanguagePolicy?
        func save(_ item: LanguagePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LanguagePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguagePolicyStore: LanguagePolicyStore {
        var items: [String: LanguagePolicy]
        var order: [String]

        init(items: [String: LanguagePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguagePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguagePolicy) {
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

        func list() -> [LanguagePolicy] {
            var out: [LanguagePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguagePolicyStore() -> any LanguagePolicyStore {
        return MemoryLanguagePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguagePolicyStore: LanguagePolicyStore {
        var inner: MemoryLanguagePolicyStore
        var cache: TTLCache<LanguagePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguagePolicyStore, cache: TTLCache<LanguagePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguagePolicy? {
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

        func save(_ item: LanguagePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguagePolicy] {
            return inner.list()
        }
    }

    static func newCachedLanguagePolicyStore(_ inner: MemoryLanguagePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguagePolicyStore {
        return CachedLanguagePolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language policies. Empty fields match all.
    final class LanguagePolicyQuery {
        var title: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minWeight: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguagePolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [LanguagePolicy]) -> [LanguagePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguagePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguagePolicies(_ store: any LanguagePolicyStore, query: LanguagePolicyQuery) -> [LanguagePolicy] {
        return query.apply(store.list())
    }
}

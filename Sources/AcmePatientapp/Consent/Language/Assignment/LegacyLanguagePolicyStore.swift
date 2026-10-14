import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy language policies by code.
    protocol LegacyLanguagePolicyStore {
        func find(_ code: String) -> LegacyLanguagePolicy?
        func save(_ item: LegacyLanguagePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyLanguagePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyLanguagePolicyStore: LegacyLanguagePolicyStore {
        var items: [String: LegacyLanguagePolicy]
        var order: [String]

        init(items: [String: LegacyLanguagePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyLanguagePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyLanguagePolicy) {
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

        func list() -> [LegacyLanguagePolicy] {
            var out: [LegacyLanguagePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyLanguagePolicyStore() -> any LegacyLanguagePolicyStore {
        return MemoryLegacyLanguagePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyLanguagePolicyStore: LegacyLanguagePolicyStore {
        var inner: MemoryLegacyLanguagePolicyStore
        var cache: TTLCache<LegacyLanguagePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyLanguagePolicyStore, cache: TTLCache<LegacyLanguagePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyLanguagePolicy? {
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

        func save(_ item: LegacyLanguagePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyLanguagePolicy] {
            return inner.list()
        }
    }

    static func newCachedLegacyLanguagePolicyStore(_ inner: MemoryLegacyLanguagePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyLanguagePolicyStore {
        return CachedLegacyLanguagePolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy language policies. Empty fields match all.
    final class LegacyLanguagePolicyQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyLanguagePolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyLanguagePolicy]) -> [LegacyLanguagePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyLanguagePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyLanguagePolicies(_ store: any LegacyLanguagePolicyStore, query: LegacyLanguagePolicyQuery) -> [LegacyLanguagePolicy] {
        return query.apply(store.list())
    }
}

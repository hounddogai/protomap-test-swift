import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped language bundles by code.
    protocol CappedLanguageBundleStore {
        func find(_ code: String) -> CappedLanguageBundle?
        func save(_ item: CappedLanguageBundle)
        func remove(_ code: String) -> Bool
        func list() -> [CappedLanguageBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedLanguageBundleStore: CappedLanguageBundleStore {
        var items: [String: CappedLanguageBundle]
        var order: [String]

        init(items: [String: CappedLanguageBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedLanguageBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedLanguageBundle) {
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

        func list() -> [CappedLanguageBundle] {
            var out: [CappedLanguageBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedLanguageBundleStore() -> any CappedLanguageBundleStore {
        return MemoryCappedLanguageBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedLanguageBundleStore: CappedLanguageBundleStore {
        var inner: MemoryCappedLanguageBundleStore
        var cache: TTLCache<CappedLanguageBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedLanguageBundleStore, cache: TTLCache<CappedLanguageBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedLanguageBundle? {
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

        func save(_ item: CappedLanguageBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedLanguageBundle] {
            return inner.list()
        }
    }

    static func newCachedCappedLanguageBundleStore(_ inner: MemoryCappedLanguageBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedLanguageBundleStore {
        return CachedCappedLanguageBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped language bundles. Empty fields match all.
    final class CappedLanguageBundleQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedLanguageBundle) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [CappedLanguageBundle]) -> [CappedLanguageBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedLanguageBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedLanguageBundles(_ store: any CappedLanguageBundleStore, query: CappedLanguageBundleQuery) -> [CappedLanguageBundle] {
        return query.apply(store.list())
    }
}

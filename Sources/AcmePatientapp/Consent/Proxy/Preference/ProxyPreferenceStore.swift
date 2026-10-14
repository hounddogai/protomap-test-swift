import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy preferences by code.
    protocol ProxyPreferenceStore {
        func find(_ code: String) -> ProxyPreference?
        func save(_ item: ProxyPreference)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyPreferenceStore: ProxyPreferenceStore {
        var items: [String: ProxyPreference]
        var order: [String]

        init(items: [String: ProxyPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyPreference) {
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

        func list() -> [ProxyPreference] {
            var out: [ProxyPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyPreferenceStore() -> any ProxyPreferenceStore {
        return MemoryProxyPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyPreferenceStore: ProxyPreferenceStore {
        var inner: MemoryProxyPreferenceStore
        var cache: TTLCache<ProxyPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyPreferenceStore, cache: TTLCache<ProxyPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyPreference? {
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

        func save(_ item: ProxyPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyPreference] {
            return inner.list()
        }
    }

    static func newCachedProxyPreferenceStore(_ inner: MemoryProxyPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyPreferenceStore {
        return CachedProxyPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy preferences. Empty fields match all.
    final class ProxyPreferenceQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyPreference]) -> [ProxyPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyPreferences(_ store: any ProxyPreferenceStore, query: ProxyPreferenceQuery) -> [ProxyPreference] {
        return query.apply(store.list())
    }
}

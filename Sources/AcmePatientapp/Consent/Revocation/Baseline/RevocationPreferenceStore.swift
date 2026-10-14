import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation preferences by code.
    protocol RevocationPreferenceStore {
        func find(_ code: String) -> RevocationPreference?
        func save(_ item: RevocationPreference)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationPreferenceStore: RevocationPreferenceStore {
        var items: [String: RevocationPreference]
        var order: [String]

        init(items: [String: RevocationPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationPreference) {
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

        func list() -> [RevocationPreference] {
            var out: [RevocationPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationPreferenceStore() -> any RevocationPreferenceStore {
        return MemoryRevocationPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationPreferenceStore: RevocationPreferenceStore {
        var inner: MemoryRevocationPreferenceStore
        var cache: TTLCache<RevocationPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationPreferenceStore, cache: TTLCache<RevocationPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationPreference? {
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

        func save(_ item: RevocationPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationPreference] {
            return inner.list()
        }
    }

    static func newCachedRevocationPreferenceStore(_ inner: MemoryRevocationPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationPreferenceStore {
        return CachedRevocationPreferenceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation preferences. Empty fields match all.
    final class RevocationPreferenceQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationPreference) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationPreference]) -> [RevocationPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationPreferences(_ store: any RevocationPreferenceStore, query: RevocationPreferenceQuery) -> [RevocationPreference] {
        return query.apply(store.list())
    }
}

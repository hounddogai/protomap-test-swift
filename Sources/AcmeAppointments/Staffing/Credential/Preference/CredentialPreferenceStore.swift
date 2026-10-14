import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential preferences by code.
    protocol CredentialPreferenceStore {
        func find(_ code: String) -> CredentialPreference?
        func save(_ item: CredentialPreference)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialPreference]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialPreferenceStore: CredentialPreferenceStore {
        var items: [String: CredentialPreference]
        var order: [String]

        init(items: [String: CredentialPreference], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialPreference? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialPreference) {
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

        func list() -> [CredentialPreference] {
            var out: [CredentialPreference] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialPreferenceStore() -> any CredentialPreferenceStore {
        return MemoryCredentialPreferenceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialPreferenceStore: CredentialPreferenceStore {
        var inner: MemoryCredentialPreferenceStore
        var cache: TTLCache<CredentialPreference>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialPreferenceStore, cache: TTLCache<CredentialPreference>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialPreference? {
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

        func save(_ item: CredentialPreference) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialPreference] {
            return inner.list()
        }
    }

    static func newCachedCredentialPreferenceStore(_ inner: MemoryCredentialPreferenceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialPreferenceStore {
        return CachedCredentialPreferenceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential preferences. Empty fields match all.
    final class CredentialPreferenceQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialPreference) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialPreference]) -> [CredentialPreference] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialPreference) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialPreferences(_ store: any CredentialPreferenceStore, query: CredentialPreferenceQuery) -> [CredentialPreference] {
        return query.apply(store.list())
    }
}

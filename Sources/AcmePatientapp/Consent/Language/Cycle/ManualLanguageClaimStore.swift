import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual language claims by code.
    protocol ManualLanguageClaimStore {
        func find(_ code: String) -> ManualLanguageClaim?
        func save(_ item: ManualLanguageClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ManualLanguageClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualLanguageClaimStore: ManualLanguageClaimStore {
        var items: [String: ManualLanguageClaim]
        var order: [String]

        init(items: [String: ManualLanguageClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualLanguageClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualLanguageClaim) {
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

        func list() -> [ManualLanguageClaim] {
            var out: [ManualLanguageClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualLanguageClaimStore() -> any ManualLanguageClaimStore {
        return MemoryManualLanguageClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualLanguageClaimStore: ManualLanguageClaimStore {
        var inner: MemoryManualLanguageClaimStore
        var cache: TTLCache<ManualLanguageClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualLanguageClaimStore, cache: TTLCache<ManualLanguageClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualLanguageClaim? {
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

        func save(_ item: ManualLanguageClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualLanguageClaim] {
            return inner.list()
        }
    }

    static func newCachedManualLanguageClaimStore(_ inner: MemoryManualLanguageClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualLanguageClaimStore {
        return CachedManualLanguageClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual language claims. Empty fields match all.
    final class ManualLanguageClaimQuery {
        var source: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualLanguageClaim) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ManualLanguageClaim]) -> [ManualLanguageClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualLanguageClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualLanguageClaims(_ store: any ManualLanguageClaimStore, query: ManualLanguageClaimQuery) -> [ManualLanguageClaim] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback language claims by code.
    protocol FallbackLanguageClaimStore {
        func find(_ code: String) -> FallbackLanguageClaim?
        func save(_ item: FallbackLanguageClaim)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackLanguageClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackLanguageClaimStore: FallbackLanguageClaimStore {
        var items: [String: FallbackLanguageClaim]
        var order: [String]

        init(items: [String: FallbackLanguageClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackLanguageClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackLanguageClaim) {
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

        func list() -> [FallbackLanguageClaim] {
            var out: [FallbackLanguageClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackLanguageClaimStore() -> any FallbackLanguageClaimStore {
        return MemoryFallbackLanguageClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackLanguageClaimStore: FallbackLanguageClaimStore {
        var inner: MemoryFallbackLanguageClaimStore
        var cache: TTLCache<FallbackLanguageClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackLanguageClaimStore, cache: TTLCache<FallbackLanguageClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackLanguageClaim? {
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

        func save(_ item: FallbackLanguageClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackLanguageClaim] {
            return inner.list()
        }
    }

    static func newCachedFallbackLanguageClaimStore(_ inner: MemoryFallbackLanguageClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackLanguageClaimStore {
        return CachedFallbackLanguageClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback language claims. Empty fields match all.
    final class FallbackLanguageClaimQuery {
        var segment: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackLanguageClaim) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackLanguageClaim]) -> [FallbackLanguageClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackLanguageClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackLanguageClaims(_ store: any FallbackLanguageClaimStore, query: FallbackLanguageClaimQuery) -> [FallbackLanguageClaim] {
        return query.apply(store.list())
    }
}

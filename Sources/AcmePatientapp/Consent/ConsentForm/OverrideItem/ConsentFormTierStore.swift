import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form tiers by code.
    protocol ConsentFormTierStore {
        func find(_ code: String) -> ConsentFormTier?
        func save(_ item: ConsentFormTier)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormTierStore: ConsentFormTierStore {
        var items: [String: ConsentFormTier]
        var order: [String]

        init(items: [String: ConsentFormTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormTier) {
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

        func list() -> [ConsentFormTier] {
            var out: [ConsentFormTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormTierStore() -> any ConsentFormTierStore {
        return MemoryConsentFormTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormTierStore: ConsentFormTierStore {
        var inner: MemoryConsentFormTierStore
        var cache: TTLCache<ConsentFormTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormTierStore, cache: TTLCache<ConsentFormTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormTier? {
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

        func save(_ item: ConsentFormTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormTier] {
            return inner.list()
        }
    }

    static func newCachedConsentFormTierStore(_ inner: MemoryConsentFormTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormTierStore {
        return CachedConsentFormTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form tiers. Empty fields match all.
    final class ConsentFormTierQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormTier]) -> [ConsentFormTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormTiers(_ store: any ConsentFormTierStore, query: ConsentFormTierQuery) -> [ConsentFormTier] {
        return query.apply(store.list())
    }
}

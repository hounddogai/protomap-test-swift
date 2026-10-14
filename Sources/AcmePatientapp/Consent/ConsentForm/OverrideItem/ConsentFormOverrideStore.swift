import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form overrides by code.
    protocol ConsentFormOverrideStore {
        func find(_ code: String) -> ConsentFormOverride?
        func save(_ item: ConsentFormOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormOverrideStore: ConsentFormOverrideStore {
        var items: [String: ConsentFormOverride]
        var order: [String]

        init(items: [String: ConsentFormOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormOverride) {
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

        func list() -> [ConsentFormOverride] {
            var out: [ConsentFormOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormOverrideStore() -> any ConsentFormOverrideStore {
        return MemoryConsentFormOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormOverrideStore: ConsentFormOverrideStore {
        var inner: MemoryConsentFormOverrideStore
        var cache: TTLCache<ConsentFormOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormOverrideStore, cache: TTLCache<ConsentFormOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormOverride? {
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

        func save(_ item: ConsentFormOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormOverride] {
            return inner.list()
        }
    }

    static func newCachedConsentFormOverrideStore(_ inner: MemoryConsentFormOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormOverrideStore {
        return CachedConsentFormOverrideStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form overrides. Empty fields match all.
    final class ConsentFormOverrideQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormOverride) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormOverride]) -> [ConsentFormOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormOverrides(_ store: any ConsentFormOverrideStore, query: ConsentFormOverrideQuery) -> [ConsentFormOverride] {
        return query.apply(store.list())
    }
}

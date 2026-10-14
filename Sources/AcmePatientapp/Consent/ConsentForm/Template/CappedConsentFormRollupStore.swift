import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped consent form rollups by code.
    protocol CappedConsentFormRollupStore {
        func find(_ code: String) -> CappedConsentFormRollup?
        func save(_ item: CappedConsentFormRollup)
        func remove(_ code: String) -> Bool
        func list() -> [CappedConsentFormRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedConsentFormRollupStore: CappedConsentFormRollupStore {
        var items: [String: CappedConsentFormRollup]
        var order: [String]

        init(items: [String: CappedConsentFormRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedConsentFormRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedConsentFormRollup) {
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

        func list() -> [CappedConsentFormRollup] {
            var out: [CappedConsentFormRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedConsentFormRollupStore() -> any CappedConsentFormRollupStore {
        return MemoryCappedConsentFormRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedConsentFormRollupStore: CappedConsentFormRollupStore {
        var inner: MemoryCappedConsentFormRollupStore
        var cache: TTLCache<CappedConsentFormRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedConsentFormRollupStore, cache: TTLCache<CappedConsentFormRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedConsentFormRollup? {
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

        func save(_ item: CappedConsentFormRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedConsentFormRollup] {
            return inner.list()
        }
    }

    static func newCachedCappedConsentFormRollupStore(_ inner: MemoryCappedConsentFormRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedConsentFormRollupStore {
        return CachedCappedConsentFormRollupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped consent form rollups. Empty fields match all.
    final class CappedConsentFormRollupQuery {
        var region: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedConsentFormRollup) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedConsentFormRollup]) -> [CappedConsentFormRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedConsentFormRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedConsentFormRollups(_ store: any CappedConsentFormRollupStore, query: CappedConsentFormRollupQuery) -> [CappedConsentFormRollup] {
        return query.apply(store.list())
    }
}

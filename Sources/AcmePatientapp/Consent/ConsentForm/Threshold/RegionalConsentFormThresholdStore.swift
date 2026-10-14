import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional consent form thresholds by code.
    protocol RegionalConsentFormThresholdStore {
        func find(_ code: String) -> RegionalConsentFormThreshold?
        func save(_ item: RegionalConsentFormThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalConsentFormThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalConsentFormThresholdStore: RegionalConsentFormThresholdStore {
        var items: [String: RegionalConsentFormThreshold]
        var order: [String]

        init(items: [String: RegionalConsentFormThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalConsentFormThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalConsentFormThreshold) {
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

        func list() -> [RegionalConsentFormThreshold] {
            var out: [RegionalConsentFormThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalConsentFormThresholdStore() -> any RegionalConsentFormThresholdStore {
        return MemoryRegionalConsentFormThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalConsentFormThresholdStore: RegionalConsentFormThresholdStore {
        var inner: MemoryRegionalConsentFormThresholdStore
        var cache: TTLCache<RegionalConsentFormThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalConsentFormThresholdStore, cache: TTLCache<RegionalConsentFormThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalConsentFormThreshold? {
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

        func save(_ item: RegionalConsentFormThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalConsentFormThreshold] {
            return inner.list()
        }
    }

    static func newCachedRegionalConsentFormThresholdStore(_ inner: MemoryRegionalConsentFormThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalConsentFormThresholdStore {
        return CachedRegionalConsentFormThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional consent form thresholds. Empty fields match all.
    final class RegionalConsentFormThresholdQuery {
        var locale: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minSequence: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalConsentFormThreshold) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [RegionalConsentFormThreshold]) -> [RegionalConsentFormThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalConsentFormThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalConsentFormThresholds(_ store: any RegionalConsentFormThresholdStore, query: RegionalConsentFormThresholdQuery) -> [RegionalConsentFormThreshold] {
        return query.apply(store.list())
    }
}

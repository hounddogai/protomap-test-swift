import AcmePlatform
import Foundation

extension Consent {
    /// Keeps adaptive consent form bundles by code.
    protocol AdaptiveConsentFormBundleStore {
        func find(_ code: String) -> AdaptiveConsentFormBundle?
        func save(_ item: AdaptiveConsentFormBundle)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveConsentFormBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveConsentFormBundleStore: AdaptiveConsentFormBundleStore {
        var items: [String: AdaptiveConsentFormBundle]
        var order: [String]

        init(items: [String: AdaptiveConsentFormBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveConsentFormBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveConsentFormBundle) {
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

        func list() -> [AdaptiveConsentFormBundle] {
            var out: [AdaptiveConsentFormBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveConsentFormBundleStore() -> any AdaptiveConsentFormBundleStore {
        return MemoryAdaptiveConsentFormBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveConsentFormBundleStore: AdaptiveConsentFormBundleStore {
        var inner: MemoryAdaptiveConsentFormBundleStore
        var cache: TTLCache<AdaptiveConsentFormBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveConsentFormBundleStore, cache: TTLCache<AdaptiveConsentFormBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveConsentFormBundle? {
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

        func save(_ item: AdaptiveConsentFormBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveConsentFormBundle] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveConsentFormBundleStore(_ inner: MemoryAdaptiveConsentFormBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveConsentFormBundleStore {
        return CachedAdaptiveConsentFormBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive consent form bundles. Empty fields match all.
    final class AdaptiveConsentFormBundleQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveConsentFormBundle) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AdaptiveConsentFormBundle]) -> [AdaptiveConsentFormBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveConsentFormBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveConsentFormBundles(_ store: any AdaptiveConsentFormBundleStore, query: AdaptiveConsentFormBundleQuery) -> [AdaptiveConsentFormBundle] {
        return query.apply(store.list())
    }
}

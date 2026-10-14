import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility bundles by code.
    protocol EligibilityBundleStore {
        func find(_ code: String) -> EligibilityBundle?
        func save(_ item: EligibilityBundle)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityBundleStore: EligibilityBundleStore {
        var items: [String: EligibilityBundle]
        var order: [String]

        init(items: [String: EligibilityBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityBundle) {
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

        func list() -> [EligibilityBundle] {
            var out: [EligibilityBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityBundleStore() -> any EligibilityBundleStore {
        return MemoryEligibilityBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityBundleStore: EligibilityBundleStore {
        var inner: MemoryEligibilityBundleStore
        var cache: TTLCache<EligibilityBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityBundleStore, cache: TTLCache<EligibilityBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityBundle? {
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

        func save(_ item: EligibilityBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityBundle] {
            return inner.list()
        }
    }

    static func newCachedEligibilityBundleStore(_ inner: MemoryEligibilityBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityBundleStore {
        return CachedEligibilityBundleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility bundles. Empty fields match all.
    final class EligibilityBundleQuery {
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

        func matches(_ item: EligibilityBundle) -> Bool {
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

        func apply(_ items: [EligibilityBundle]) -> [EligibilityBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityBundles(_ store: any EligibilityBundleStore, query: EligibilityBundleQuery) -> [EligibilityBundle] {
        return query.apply(store.list())
    }
}

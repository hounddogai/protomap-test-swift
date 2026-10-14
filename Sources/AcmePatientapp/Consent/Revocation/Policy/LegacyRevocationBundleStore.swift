import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy revocation bundles by code.
    protocol LegacyRevocationBundleStore {
        func find(_ code: String) -> LegacyRevocationBundle?
        func save(_ item: LegacyRevocationBundle)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyRevocationBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyRevocationBundleStore: LegacyRevocationBundleStore {
        var items: [String: LegacyRevocationBundle]
        var order: [String]

        init(items: [String: LegacyRevocationBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyRevocationBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyRevocationBundle) {
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

        func list() -> [LegacyRevocationBundle] {
            var out: [LegacyRevocationBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyRevocationBundleStore() -> any LegacyRevocationBundleStore {
        return MemoryLegacyRevocationBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyRevocationBundleStore: LegacyRevocationBundleStore {
        var inner: MemoryLegacyRevocationBundleStore
        var cache: TTLCache<LegacyRevocationBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyRevocationBundleStore, cache: TTLCache<LegacyRevocationBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyRevocationBundle? {
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

        func save(_ item: LegacyRevocationBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyRevocationBundle] {
            return inner.list()
        }
    }

    static func newCachedLegacyRevocationBundleStore(_ inner: MemoryLegacyRevocationBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyRevocationBundleStore {
        return CachedLegacyRevocationBundleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy revocation bundles. Empty fields match all.
    final class LegacyRevocationBundleQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyRevocationBundle) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyRevocationBundle]) -> [LegacyRevocationBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyRevocationBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyRevocationBundles(_ store: any LegacyRevocationBundleStore, query: LegacyRevocationBundleQuery) -> [LegacyRevocationBundle] {
        return query.apply(store.list())
    }
}

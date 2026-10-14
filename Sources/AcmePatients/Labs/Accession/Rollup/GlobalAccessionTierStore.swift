import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global accession tiers by code.
    protocol GlobalAccessionTierStore {
        func find(_ code: String) -> GlobalAccessionTier?
        func save(_ item: GlobalAccessionTier)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAccessionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAccessionTierStore: GlobalAccessionTierStore {
        var items: [String: GlobalAccessionTier]
        var order: [String]

        init(items: [String: GlobalAccessionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAccessionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAccessionTier) {
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

        func list() -> [GlobalAccessionTier] {
            var out: [GlobalAccessionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAccessionTierStore() -> any GlobalAccessionTierStore {
        return MemoryGlobalAccessionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAccessionTierStore: GlobalAccessionTierStore {
        var inner: MemoryGlobalAccessionTierStore
        var cache: TTLCache<GlobalAccessionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAccessionTierStore, cache: TTLCache<GlobalAccessionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAccessionTier? {
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

        func save(_ item: GlobalAccessionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAccessionTier] {
            return inner.list()
        }
    }

    static func newCachedGlobalAccessionTierStore(_ inner: MemoryGlobalAccessionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAccessionTierStore {
        return CachedGlobalAccessionTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global accession tiers. Empty fields match all.
    final class GlobalAccessionTierQuery {
        var locale: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMargin: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAccessionTier) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAccessionTier]) -> [GlobalAccessionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAccessionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAccessionTiers(_ store: any GlobalAccessionTierStore, query: GlobalAccessionTierQuery) -> [GlobalAccessionTier] {
        return query.apply(store.list())
    }
}

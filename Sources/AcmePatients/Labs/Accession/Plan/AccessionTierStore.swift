import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession tiers by code.
    protocol AccessionTierStore {
        func find(_ code: String) -> AccessionTier?
        func save(_ item: AccessionTier)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionTierStore: AccessionTierStore {
        var items: [String: AccessionTier]
        var order: [String]

        init(items: [String: AccessionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionTier) {
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

        func list() -> [AccessionTier] {
            var out: [AccessionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionTierStore() -> any AccessionTierStore {
        return MemoryAccessionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionTierStore: AccessionTierStore {
        var inner: MemoryAccessionTierStore
        var cache: TTLCache<AccessionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionTierStore, cache: TTLCache<AccessionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionTier? {
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

        func save(_ item: AccessionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionTier] {
            return inner.list()
        }
    }

    static func newCachedAccessionTierStore(_ inner: MemoryAccessionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionTierStore {
        return CachedAccessionTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession tiers. Empty fields match all.
    final class AccessionTierQuery {
        var source: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionTier) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionTier]) -> [AccessionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionTiers(_ store: any AccessionTierStore, query: AccessionTierQuery) -> [AccessionTier] {
        return query.apply(store.list())
    }
}

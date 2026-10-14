import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy witness tiers by code.
    protocol LegacyWitnessTierStore {
        func find(_ code: String) -> LegacyWitnessTier?
        func save(_ item: LegacyWitnessTier)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyWitnessTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyWitnessTierStore: LegacyWitnessTierStore {
        var items: [String: LegacyWitnessTier]
        var order: [String]

        init(items: [String: LegacyWitnessTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyWitnessTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyWitnessTier) {
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

        func list() -> [LegacyWitnessTier] {
            var out: [LegacyWitnessTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyWitnessTierStore() -> any LegacyWitnessTierStore {
        return MemoryLegacyWitnessTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyWitnessTierStore: LegacyWitnessTierStore {
        var inner: MemoryLegacyWitnessTierStore
        var cache: TTLCache<LegacyWitnessTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyWitnessTierStore, cache: TTLCache<LegacyWitnessTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyWitnessTier? {
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

        func save(_ item: LegacyWitnessTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyWitnessTier] {
            return inner.list()
        }
    }

    static func newCachedLegacyWitnessTierStore(_ inner: MemoryLegacyWitnessTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyWitnessTierStore {
        return CachedLegacyWitnessTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy witness tiers. Empty fields match all.
    final class LegacyWitnessTierQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyWitnessTier) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyWitnessTier]) -> [LegacyWitnessTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyWitnessTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyWitnessTiers(_ store: any LegacyWitnessTierStore, query: LegacyWitnessTierQuery) -> [LegacyWitnessTier] {
        return query.apply(store.list())
    }
}

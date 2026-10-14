import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive specimen ledgers by code.
    protocol AdaptiveSpecimenLedgerStore {
        func find(_ code: String) -> AdaptiveSpecimenLedger?
        func save(_ item: AdaptiveSpecimenLedger)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveSpecimenLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveSpecimenLedgerStore: AdaptiveSpecimenLedgerStore {
        var items: [String: AdaptiveSpecimenLedger]
        var order: [String]

        init(items: [String: AdaptiveSpecimenLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveSpecimenLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveSpecimenLedger) {
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

        func list() -> [AdaptiveSpecimenLedger] {
            var out: [AdaptiveSpecimenLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveSpecimenLedgerStore() -> any AdaptiveSpecimenLedgerStore {
        return MemoryAdaptiveSpecimenLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveSpecimenLedgerStore: AdaptiveSpecimenLedgerStore {
        var inner: MemoryAdaptiveSpecimenLedgerStore
        var cache: TTLCache<AdaptiveSpecimenLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveSpecimenLedgerStore, cache: TTLCache<AdaptiveSpecimenLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveSpecimenLedger? {
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

        func save(_ item: AdaptiveSpecimenLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveSpecimenLedger] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveSpecimenLedgerStore(_ inner: MemoryAdaptiveSpecimenLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveSpecimenLedgerStore {
        return CachedAdaptiveSpecimenLedgerStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive specimen ledgers. Empty fields match all.
    final class AdaptiveSpecimenLedgerQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveSpecimenLedger) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveSpecimenLedger]) -> [AdaptiveSpecimenLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveSpecimenLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveSpecimenLedgers(_ store: any AdaptiveSpecimenLedgerStore, query: AdaptiveSpecimenLedgerQuery) -> [AdaptiveSpecimenLedger] {
        return query.apply(store.list())
    }
}

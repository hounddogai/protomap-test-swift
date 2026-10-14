import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility entries by code.
    protocol EligibilityEntryStore {
        func find(_ code: String) -> EligibilityEntry?
        func save(_ item: EligibilityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityEntryStore: EligibilityEntryStore {
        var items: [String: EligibilityEntry]
        var order: [String]

        init(items: [String: EligibilityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityEntry) {
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

        func list() -> [EligibilityEntry] {
            var out: [EligibilityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityEntryStore() -> any EligibilityEntryStore {
        return MemoryEligibilityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityEntryStore: EligibilityEntryStore {
        var inner: MemoryEligibilityEntryStore
        var cache: TTLCache<EligibilityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityEntryStore, cache: TTLCache<EligibilityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityEntry? {
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

        func save(_ item: EligibilityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityEntry] {
            return inner.list()
        }
    }

    static func newCachedEligibilityEntryStore(_ inner: MemoryEligibilityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityEntryStore {
        return CachedEligibilityEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility entries. Empty fields match all.
    final class EligibilityEntryQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityEntry]) -> [EligibilityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityEntries(_ store: any EligibilityEntryStore, query: EligibilityEntryQuery) -> [EligibilityEntry] {
        return query.apply(store.list())
    }
}

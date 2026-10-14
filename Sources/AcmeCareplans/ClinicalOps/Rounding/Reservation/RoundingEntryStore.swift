import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding entries by code.
    protocol RoundingEntryStore {
        func find(_ code: String) -> RoundingEntry?
        func save(_ item: RoundingEntry)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingEntryStore: RoundingEntryStore {
        var items: [String: RoundingEntry]
        var order: [String]

        init(items: [String: RoundingEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingEntry) {
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

        func list() -> [RoundingEntry] {
            var out: [RoundingEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingEntryStore() -> any RoundingEntryStore {
        return MemoryRoundingEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingEntryStore: RoundingEntryStore {
        var inner: MemoryRoundingEntryStore
        var cache: TTLCache<RoundingEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingEntryStore, cache: TTLCache<RoundingEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingEntry? {
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

        func save(_ item: RoundingEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingEntry] {
            return inner.list()
        }
    }

    static func newCachedRoundingEntryStore(_ inner: MemoryRoundingEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingEntryStore {
        return CachedRoundingEntryStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding entries. Empty fields match all.
    final class RoundingEntryQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingEntry) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RoundingEntry]) -> [RoundingEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingEntries(_ store: any RoundingEntryStore, query: RoundingEntryQuery) -> [RoundingEntry] {
        return query.apply(store.list())
    }
}

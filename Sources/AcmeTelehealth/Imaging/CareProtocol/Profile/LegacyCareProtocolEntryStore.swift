import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps legacy care protocol entries by code.
    protocol LegacyCareProtocolEntryStore {
        func find(_ code: String) -> LegacyCareProtocolEntry?
        func save(_ item: LegacyCareProtocolEntry)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCareProtocolEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCareProtocolEntryStore: LegacyCareProtocolEntryStore {
        var items: [String: LegacyCareProtocolEntry]
        var order: [String]

        init(items: [String: LegacyCareProtocolEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCareProtocolEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCareProtocolEntry) {
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

        func list() -> [LegacyCareProtocolEntry] {
            var out: [LegacyCareProtocolEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCareProtocolEntryStore() -> any LegacyCareProtocolEntryStore {
        return MemoryLegacyCareProtocolEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCareProtocolEntryStore: LegacyCareProtocolEntryStore {
        var inner: MemoryLegacyCareProtocolEntryStore
        var cache: TTLCache<LegacyCareProtocolEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCareProtocolEntryStore, cache: TTLCache<LegacyCareProtocolEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCareProtocolEntry? {
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

        func save(_ item: LegacyCareProtocolEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCareProtocolEntry] {
            return inner.list()
        }
    }

    static func newCachedLegacyCareProtocolEntryStore(_ inner: MemoryLegacyCareProtocolEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCareProtocolEntryStore {
        return CachedLegacyCareProtocolEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy care protocol entries. Empty fields match all.
    final class LegacyCareProtocolEntryQuery {
        var facility: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCareProtocolEntry) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCareProtocolEntry]) -> [LegacyCareProtocolEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCareProtocolEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCareProtocolEntries(_ store: any LegacyCareProtocolEntryStore, query: LegacyCareProtocolEntryQuery) -> [LegacyCareProtocolEntry] {
        return query.apply(store.list())
    }
}

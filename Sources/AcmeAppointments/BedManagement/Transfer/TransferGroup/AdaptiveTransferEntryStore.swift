import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive transfer entries by code.
    protocol AdaptiveTransferEntryStore {
        func find(_ code: String) -> AdaptiveTransferEntry?
        func save(_ item: AdaptiveTransferEntry)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveTransferEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveTransferEntryStore: AdaptiveTransferEntryStore {
        var items: [String: AdaptiveTransferEntry]
        var order: [String]

        init(items: [String: AdaptiveTransferEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveTransferEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveTransferEntry) {
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

        func list() -> [AdaptiveTransferEntry] {
            var out: [AdaptiveTransferEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveTransferEntryStore() -> any AdaptiveTransferEntryStore {
        return MemoryAdaptiveTransferEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveTransferEntryStore: AdaptiveTransferEntryStore {
        var inner: MemoryAdaptiveTransferEntryStore
        var cache: TTLCache<AdaptiveTransferEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveTransferEntryStore, cache: TTLCache<AdaptiveTransferEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveTransferEntry? {
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

        func save(_ item: AdaptiveTransferEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveTransferEntry] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveTransferEntryStore(_ inner: MemoryAdaptiveTransferEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveTransferEntryStore {
        return CachedAdaptiveTransferEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive transfer entries. Empty fields match all.
    final class AdaptiveTransferEntryQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveTransferEntry) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveTransferEntry]) -> [AdaptiveTransferEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveTransferEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveTransferEntries(_ store: any AdaptiveTransferEntryStore, query: AdaptiveTransferEntryQuery) -> [AdaptiveTransferEntry] {
        return query.apply(store.list())
    }
}

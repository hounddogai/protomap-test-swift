import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality entries by code.
    protocol ModalityEntryStore {
        func find(_ code: String) -> ModalityEntry?
        func save(_ item: ModalityEntry)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityEntryStore: ModalityEntryStore {
        var items: [String: ModalityEntry]
        var order: [String]

        init(items: [String: ModalityEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityEntry) {
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

        func list() -> [ModalityEntry] {
            var out: [ModalityEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityEntryStore() -> any ModalityEntryStore {
        return MemoryModalityEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityEntryStore: ModalityEntryStore {
        var inner: MemoryModalityEntryStore
        var cache: TTLCache<ModalityEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityEntryStore, cache: TTLCache<ModalityEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityEntry? {
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

        func save(_ item: ModalityEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityEntry] {
            return inner.list()
        }
    }

    static func newCachedModalityEntryStore(_ inner: MemoryModalityEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityEntryStore {
        return CachedModalityEntryStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality entries. Empty fields match all.
    final class ModalityEntryQuery {
        var region: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMargin: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityEntry) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ModalityEntry]) -> [ModalityEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityEntries(_ store: any ModalityEntryStore, query: ModalityEntryQuery) -> [ModalityEntry] {
        return query.apply(store.list())
    }
}

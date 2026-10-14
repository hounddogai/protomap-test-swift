import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel records by code.
    protocol PanelRecordStore {
        func find(_ code: String) -> PanelRecord?
        func save(_ item: PanelRecord)
        func remove(_ code: String) -> Bool
        func list() -> [PanelRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelRecordStore: PanelRecordStore {
        var items: [String: PanelRecord]
        var order: [String]

        init(items: [String: PanelRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelRecord) {
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

        func list() -> [PanelRecord] {
            var out: [PanelRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelRecordStore() -> any PanelRecordStore {
        return MemoryPanelRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelRecordStore: PanelRecordStore {
        var inner: MemoryPanelRecordStore
        var cache: TTLCache<PanelRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelRecordStore, cache: TTLCache<PanelRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelRecord? {
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

        func save(_ item: PanelRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelRecord] {
            return inner.list()
        }
    }

    static func newCachedPanelRecordStore(_ inner: MemoryPanelRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelRecordStore {
        return CachedPanelRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel records. Empty fields match all.
    final class PanelRecordQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PanelRecord]) -> [PanelRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelRecords(_ store: any PanelRecordStore, query: PanelRecordQuery) -> [PanelRecord] {
        return query.apply(store.list())
    }
}

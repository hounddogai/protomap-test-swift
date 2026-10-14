import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool entries by code.
    protocol FloatPoolEntryStore {
        func find(_ code: String) -> FloatPoolEntry?
        func save(_ item: FloatPoolEntry)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolEntryStore: FloatPoolEntryStore {
        var items: [String: FloatPoolEntry]
        var order: [String]

        init(items: [String: FloatPoolEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolEntry) {
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

        func list() -> [FloatPoolEntry] {
            var out: [FloatPoolEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolEntryStore() -> any FloatPoolEntryStore {
        return MemoryFloatPoolEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolEntryStore: FloatPoolEntryStore {
        var inner: MemoryFloatPoolEntryStore
        var cache: TTLCache<FloatPoolEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolEntryStore, cache: TTLCache<FloatPoolEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolEntry? {
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

        func save(_ item: FloatPoolEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolEntry] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolEntryStore(_ inner: MemoryFloatPoolEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolEntryStore {
        return CachedFloatPoolEntryStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool entries. Empty fields match all.
    final class FloatPoolEntryQuery {
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

        func matches(_ item: FloatPoolEntry) -> Bool {
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

        func apply(_ items: [FloatPoolEntry]) -> [FloatPoolEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolEntries(_ store: any FloatPoolEntryStore, query: FloatPoolEntryQuery) -> [FloatPoolEntry] {
        return query.apply(store.list())
    }
}

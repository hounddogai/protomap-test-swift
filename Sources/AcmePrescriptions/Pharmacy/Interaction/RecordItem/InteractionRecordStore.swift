import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction records by code.
    protocol InteractionRecordStore {
        func find(_ code: String) -> InteractionRecord?
        func save(_ item: InteractionRecord)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionRecordStore: InteractionRecordStore {
        var items: [String: InteractionRecord]
        var order: [String]

        init(items: [String: InteractionRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionRecord) {
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

        func list() -> [InteractionRecord] {
            var out: [InteractionRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionRecordStore() -> any InteractionRecordStore {
        return MemoryInteractionRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionRecordStore: InteractionRecordStore {
        var inner: MemoryInteractionRecordStore
        var cache: TTLCache<InteractionRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionRecordStore, cache: TTLCache<InteractionRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionRecord? {
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

        func save(_ item: InteractionRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionRecord] {
            return inner.list()
        }
    }

    static func newCachedInteractionRecordStore(_ inner: MemoryInteractionRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionRecordStore {
        return CachedInteractionRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction records. Empty fields match all.
    final class InteractionRecordQuery {
        var name: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRate: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionRecord]) -> [InteractionRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionRecords(_ store: any InteractionRecordStore, query: InteractionRecordQuery) -> [InteractionRecord] {
        return query.apply(store.list())
    }
}

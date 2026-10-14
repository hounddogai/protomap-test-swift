import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set segments by code.
    protocol OrderSetSegmentStore {
        func find(_ code: String) -> OrderSetSegment?
        func save(_ item: OrderSetSegment)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetSegmentStore: OrderSetSegmentStore {
        var items: [String: OrderSetSegment]
        var order: [String]

        init(items: [String: OrderSetSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetSegment) {
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

        func list() -> [OrderSetSegment] {
            var out: [OrderSetSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetSegmentStore() -> any OrderSetSegmentStore {
        return MemoryOrderSetSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetSegmentStore: OrderSetSegmentStore {
        var inner: MemoryOrderSetSegmentStore
        var cache: TTLCache<OrderSetSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetSegmentStore, cache: TTLCache<OrderSetSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetSegment? {
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

        func save(_ item: OrderSetSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetSegment] {
            return inner.list()
        }
    }

    static func newCachedOrderSetSegmentStore(_ inner: MemoryOrderSetSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetSegmentStore {
        return CachedOrderSetSegmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set segments. Empty fields match all.
    final class OrderSetSegmentQuery {
        var locale: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRevision: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetSegment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetSegment]) -> [OrderSetSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetSegments(_ store: any OrderSetSegmentStore, query: OrderSetSegmentQuery) -> [OrderSetSegment] {
        return query.apply(store.list())
    }
}

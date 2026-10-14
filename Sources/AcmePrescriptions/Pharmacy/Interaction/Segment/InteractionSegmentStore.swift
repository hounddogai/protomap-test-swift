import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction segments by code.
    protocol InteractionSegmentStore {
        func find(_ code: String) -> InteractionSegment?
        func save(_ item: InteractionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionSegmentStore: InteractionSegmentStore {
        var items: [String: InteractionSegment]
        var order: [String]

        init(items: [String: InteractionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionSegment) {
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

        func list() -> [InteractionSegment] {
            var out: [InteractionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionSegmentStore() -> any InteractionSegmentStore {
        return MemoryInteractionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionSegmentStore: InteractionSegmentStore {
        var inner: MemoryInteractionSegmentStore
        var cache: TTLCache<InteractionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionSegmentStore, cache: TTLCache<InteractionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionSegment? {
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

        func save(_ item: InteractionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionSegment] {
            return inner.list()
        }
    }

    static func newCachedInteractionSegmentStore(_ inner: MemoryInteractionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionSegmentStore {
        return CachedInteractionSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction segments. Empty fields match all.
    final class InteractionSegmentQuery {
        var category: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRefills: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionSegment) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionSegment]) -> [InteractionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionSegments(_ store: any InteractionSegmentStore, query: InteractionSegmentQuery) -> [InteractionSegment] {
        return query.apply(store.list())
    }
}

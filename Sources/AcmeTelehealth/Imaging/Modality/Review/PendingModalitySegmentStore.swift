import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending modality segments by code.
    protocol PendingModalitySegmentStore {
        func find(_ code: String) -> PendingModalitySegment?
        func save(_ item: PendingModalitySegment)
        func remove(_ code: String) -> Bool
        func list() -> [PendingModalitySegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingModalitySegmentStore: PendingModalitySegmentStore {
        var items: [String: PendingModalitySegment]
        var order: [String]

        init(items: [String: PendingModalitySegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingModalitySegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingModalitySegment) {
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

        func list() -> [PendingModalitySegment] {
            var out: [PendingModalitySegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingModalitySegmentStore() -> any PendingModalitySegmentStore {
        return MemoryPendingModalitySegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingModalitySegmentStore: PendingModalitySegmentStore {
        var inner: MemoryPendingModalitySegmentStore
        var cache: TTLCache<PendingModalitySegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingModalitySegmentStore, cache: TTLCache<PendingModalitySegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingModalitySegment? {
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

        func save(_ item: PendingModalitySegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingModalitySegment] {
            return inner.list()
        }
    }

    static func newCachedPendingModalitySegmentStore(_ inner: MemoryPendingModalitySegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingModalitySegmentStore {
        return CachedPendingModalitySegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending modality segments. Empty fields match all.
    final class PendingModalitySegmentQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingModalitySegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingModalitySegment]) -> [PendingModalitySegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingModalitySegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingModalitySegments(_ store: any PendingModalitySegmentStore, query: PendingModalitySegmentQuery) -> [PendingModalitySegment] {
        return query.apply(store.list())
    }
}

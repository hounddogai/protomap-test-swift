import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel segments by code.
    protocol PanelSegmentStore {
        func find(_ code: String) -> PanelSegment?
        func save(_ item: PanelSegment)
        func remove(_ code: String) -> Bool
        func list() -> [PanelSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelSegmentStore: PanelSegmentStore {
        var items: [String: PanelSegment]
        var order: [String]

        init(items: [String: PanelSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelSegment) {
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

        func list() -> [PanelSegment] {
            var out: [PanelSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelSegmentStore() -> any PanelSegmentStore {
        return MemoryPanelSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelSegmentStore: PanelSegmentStore {
        var inner: MemoryPanelSegmentStore
        var cache: TTLCache<PanelSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelSegmentStore, cache: TTLCache<PanelSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelSegment? {
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

        func save(_ item: PanelSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelSegment] {
            return inner.list()
        }
    }

    static func newCachedPanelSegmentStore(_ inner: MemoryPanelSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelSegmentStore {
        return CachedPanelSegmentStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel segments. Empty fields match all.
    final class PanelSegmentQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PanelSegment]) -> [PanelSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelSegments(_ store: any PanelSegmentStore, query: PanelSegmentQuery) -> [PanelSegment] {
        return query.apply(store.list())
    }
}

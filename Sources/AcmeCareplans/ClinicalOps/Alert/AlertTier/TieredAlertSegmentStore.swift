import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered alert segments by code.
    protocol TieredAlertSegmentStore {
        func find(_ code: String) -> TieredAlertSegment?
        func save(_ item: TieredAlertSegment)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAlertSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAlertSegmentStore: TieredAlertSegmentStore {
        var items: [String: TieredAlertSegment]
        var order: [String]

        init(items: [String: TieredAlertSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAlertSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAlertSegment) {
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

        func list() -> [TieredAlertSegment] {
            var out: [TieredAlertSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAlertSegmentStore() -> any TieredAlertSegmentStore {
        return MemoryTieredAlertSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAlertSegmentStore: TieredAlertSegmentStore {
        var inner: MemoryTieredAlertSegmentStore
        var cache: TTLCache<TieredAlertSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAlertSegmentStore, cache: TTLCache<TieredAlertSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAlertSegment? {
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

        func save(_ item: TieredAlertSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAlertSegment] {
            return inner.list()
        }
    }

    static func newCachedTieredAlertSegmentStore(_ inner: MemoryTieredAlertSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAlertSegmentStore {
        return CachedTieredAlertSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered alert segments. Empty fields match all.
    final class TieredAlertSegmentQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredAlertSegment) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredAlertSegment]) -> [TieredAlertSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAlertSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAlertSegments(_ store: any TieredAlertSegmentStore, query: TieredAlertSegmentQuery) -> [TieredAlertSegment] {
        return query.apply(store.list())
    }
}

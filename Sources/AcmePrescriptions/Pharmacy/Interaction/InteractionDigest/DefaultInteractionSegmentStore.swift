import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps default interaction segments by code.
    protocol DefaultInteractionSegmentStore {
        func find(_ code: String) -> DefaultInteractionSegment?
        func save(_ item: DefaultInteractionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultInteractionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultInteractionSegmentStore: DefaultInteractionSegmentStore {
        var items: [String: DefaultInteractionSegment]
        var order: [String]

        init(items: [String: DefaultInteractionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultInteractionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultInteractionSegment) {
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

        func list() -> [DefaultInteractionSegment] {
            var out: [DefaultInteractionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultInteractionSegmentStore() -> any DefaultInteractionSegmentStore {
        return MemoryDefaultInteractionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultInteractionSegmentStore: DefaultInteractionSegmentStore {
        var inner: MemoryDefaultInteractionSegmentStore
        var cache: TTLCache<DefaultInteractionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultInteractionSegmentStore, cache: TTLCache<DefaultInteractionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultInteractionSegment? {
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

        func save(_ item: DefaultInteractionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultInteractionSegment] {
            return inner.list()
        }
    }

    static func newCachedDefaultInteractionSegmentStore(_ inner: MemoryDefaultInteractionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultInteractionSegmentStore {
        return CachedDefaultInteractionSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default interaction segments. Empty fields match all.
    final class DefaultInteractionSegmentQuery {
        var source: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultInteractionSegment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultInteractionSegment]) -> [DefaultInteractionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultInteractionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultInteractionSegments(_ store: any DefaultInteractionSegmentStore, query: DefaultInteractionSegmentQuery) -> [DefaultInteractionSegment] {
        return query.apply(store.list())
    }
}

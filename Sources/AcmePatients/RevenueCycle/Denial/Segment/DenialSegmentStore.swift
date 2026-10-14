import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial segments by code.
    protocol DenialSegmentStore {
        func find(_ code: String) -> DenialSegment?
        func save(_ item: DenialSegment)
        func remove(_ code: String) -> Bool
        func list() -> [DenialSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialSegmentStore: DenialSegmentStore {
        var items: [String: DenialSegment]
        var order: [String]

        init(items: [String: DenialSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialSegment) {
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

        func list() -> [DenialSegment] {
            var out: [DenialSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialSegmentStore() -> any DenialSegmentStore {
        return MemoryDenialSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialSegmentStore: DenialSegmentStore {
        var inner: MemoryDenialSegmentStore
        var cache: TTLCache<DenialSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialSegmentStore, cache: TTLCache<DenialSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialSegment? {
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

        func save(_ item: DenialSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialSegment] {
            return inner.list()
        }
    }

    static func newCachedDenialSegmentStore(_ inner: MemoryDenialSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialSegmentStore {
        return CachedDenialSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial segments. Empty fields match all.
    final class DenialSegmentQuery {
        var locale: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialSegment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialSegment]) -> [DenialSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialSegments(_ store: any DenialSegmentStore, query: DenialSegmentQuery) -> [DenialSegment] {
        return query.apply(store.list())
    }
}

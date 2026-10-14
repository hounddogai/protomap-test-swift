import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient care protocol segments by code.
    protocol LenientCareProtocolSegmentStore {
        func find(_ code: String) -> LenientCareProtocolSegment?
        func save(_ item: LenientCareProtocolSegment)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCareProtocolSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCareProtocolSegmentStore: LenientCareProtocolSegmentStore {
        var items: [String: LenientCareProtocolSegment]
        var order: [String]

        init(items: [String: LenientCareProtocolSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCareProtocolSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCareProtocolSegment) {
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

        func list() -> [LenientCareProtocolSegment] {
            var out: [LenientCareProtocolSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCareProtocolSegmentStore() -> any LenientCareProtocolSegmentStore {
        return MemoryLenientCareProtocolSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCareProtocolSegmentStore: LenientCareProtocolSegmentStore {
        var inner: MemoryLenientCareProtocolSegmentStore
        var cache: TTLCache<LenientCareProtocolSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCareProtocolSegmentStore, cache: TTLCache<LenientCareProtocolSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCareProtocolSegment? {
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

        func save(_ item: LenientCareProtocolSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCareProtocolSegment] {
            return inner.list()
        }
    }

    static func newCachedLenientCareProtocolSegmentStore(_ inner: MemoryLenientCareProtocolSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCareProtocolSegmentStore {
        return CachedLenientCareProtocolSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient care protocol segments. Empty fields match all.
    final class LenientCareProtocolSegmentQuery {
        var locale: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minRate: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCareProtocolSegment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LenientCareProtocolSegment]) -> [LenientCareProtocolSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCareProtocolSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCareProtocolSegments(_ store: any LenientCareProtocolSegmentStore, query: LenientCareProtocolSegmentQuery) -> [LenientCareProtocolSegment] {
        return query.apply(store.list())
    }
}

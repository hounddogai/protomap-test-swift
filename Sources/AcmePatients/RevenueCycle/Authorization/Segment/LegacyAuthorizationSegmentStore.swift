import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy authorization segments by code.
    protocol LegacyAuthorizationSegmentStore {
        func find(_ code: String) -> LegacyAuthorizationSegment?
        func save(_ item: LegacyAuthorizationSegment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAuthorizationSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAuthorizationSegmentStore: LegacyAuthorizationSegmentStore {
        var items: [String: LegacyAuthorizationSegment]
        var order: [String]

        init(items: [String: LegacyAuthorizationSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAuthorizationSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAuthorizationSegment) {
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

        func list() -> [LegacyAuthorizationSegment] {
            var out: [LegacyAuthorizationSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAuthorizationSegmentStore() -> any LegacyAuthorizationSegmentStore {
        return MemoryLegacyAuthorizationSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAuthorizationSegmentStore: LegacyAuthorizationSegmentStore {
        var inner: MemoryLegacyAuthorizationSegmentStore
        var cache: TTLCache<LegacyAuthorizationSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAuthorizationSegmentStore, cache: TTLCache<LegacyAuthorizationSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAuthorizationSegment? {
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

        func save(_ item: LegacyAuthorizationSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAuthorizationSegment] {
            return inner.list()
        }
    }

    static func newCachedLegacyAuthorizationSegmentStore(_ inner: MemoryLegacyAuthorizationSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAuthorizationSegmentStore {
        return CachedLegacyAuthorizationSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy authorization segments. Empty fields match all.
    final class LegacyAuthorizationSegmentQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAuthorizationSegment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAuthorizationSegment]) -> [LegacyAuthorizationSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAuthorizationSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAuthorizationSegments(_ store: any LegacyAuthorizationSegmentStore, query: LegacyAuthorizationSegmentQuery) -> [LegacyAuthorizationSegment] {
        return query.apply(store.list())
    }
}

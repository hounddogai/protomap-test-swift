import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy interaction segments by code.
    protocol LegacyInteractionSegmentStore {
        func find(_ code: String) -> LegacyInteractionSegment?
        func save(_ item: LegacyInteractionSegment)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyInteractionSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyInteractionSegmentStore: LegacyInteractionSegmentStore {
        var items: [String: LegacyInteractionSegment]
        var order: [String]

        init(items: [String: LegacyInteractionSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyInteractionSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyInteractionSegment) {
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

        func list() -> [LegacyInteractionSegment] {
            var out: [LegacyInteractionSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyInteractionSegmentStore() -> any LegacyInteractionSegmentStore {
        return MemoryLegacyInteractionSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyInteractionSegmentStore: LegacyInteractionSegmentStore {
        var inner: MemoryLegacyInteractionSegmentStore
        var cache: TTLCache<LegacyInteractionSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyInteractionSegmentStore, cache: TTLCache<LegacyInteractionSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyInteractionSegment? {
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

        func save(_ item: LegacyInteractionSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyInteractionSegment] {
            return inner.list()
        }
    }

    static func newCachedLegacyInteractionSegmentStore(_ inner: MemoryLegacyInteractionSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyInteractionSegmentStore {
        return CachedLegacyInteractionSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy interaction segments. Empty fields match all.
    final class LegacyInteractionSegmentQuery {
        var locale: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minLimit: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyInteractionSegment) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyInteractionSegment]) -> [LegacyInteractionSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyInteractionSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyInteractionSegments(_ store: any LegacyInteractionSegmentStore, query: LegacyInteractionSegmentQuery) -> [LegacyInteractionSegment] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form segments by code.
    protocol ConsentFormSegmentStore {
        func find(_ code: String) -> ConsentFormSegment?
        func save(_ item: ConsentFormSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormSegmentStore: ConsentFormSegmentStore {
        var items: [String: ConsentFormSegment]
        var order: [String]

        init(items: [String: ConsentFormSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormSegment) {
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

        func list() -> [ConsentFormSegment] {
            var out: [ConsentFormSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormSegmentStore() -> any ConsentFormSegmentStore {
        return MemoryConsentFormSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormSegmentStore: ConsentFormSegmentStore {
        var inner: MemoryConsentFormSegmentStore
        var cache: TTLCache<ConsentFormSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormSegmentStore, cache: TTLCache<ConsentFormSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormSegment? {
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

        func save(_ item: ConsentFormSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormSegment] {
            return inner.list()
        }
    }

    static func newCachedConsentFormSegmentStore(_ inner: MemoryConsentFormSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormSegmentStore {
        return CachedConsentFormSegmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form segments. Empty fields match all.
    final class ConsentFormSegmentQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormSegment) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormSegment]) -> [ConsentFormSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormSegments(_ store: any ConsentFormSegmentStore, query: ConsentFormSegmentQuery) -> [ConsentFormSegment] {
        return query.apply(store.list())
    }
}

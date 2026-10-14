import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance segments by code.
    protocol RemittanceSegmentStore {
        func find(_ code: String) -> RemittanceSegment?
        func save(_ item: RemittanceSegment)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceSegmentStore: RemittanceSegmentStore {
        var items: [String: RemittanceSegment]
        var order: [String]

        init(items: [String: RemittanceSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceSegment) {
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

        func list() -> [RemittanceSegment] {
            var out: [RemittanceSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceSegmentStore() -> any RemittanceSegmentStore {
        return MemoryRemittanceSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceSegmentStore: RemittanceSegmentStore {
        var inner: MemoryRemittanceSegmentStore
        var cache: TTLCache<RemittanceSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceSegmentStore, cache: TTLCache<RemittanceSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceSegment? {
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

        func save(_ item: RemittanceSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceSegment] {
            return inner.list()
        }
    }

    static func newCachedRemittanceSegmentStore(_ inner: MemoryRemittanceSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceSegmentStore {
        return CachedRemittanceSegmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance segments. Empty fields match all.
    final class RemittanceSegmentQuery {
        var segment: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRetries: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceSegment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceSegment]) -> [RemittanceSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceSegments(_ store: any RemittanceSegmentStore, query: RemittanceSegmentQuery) -> [RemittanceSegment] {
        return query.apply(store.list())
    }
}

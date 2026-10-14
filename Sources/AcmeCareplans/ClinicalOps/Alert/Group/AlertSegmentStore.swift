import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert segments by code.
    protocol AlertSegmentStore {
        func find(_ code: String) -> AlertSegment?
        func save(_ item: AlertSegment)
        func remove(_ code: String) -> Bool
        func list() -> [AlertSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertSegmentStore: AlertSegmentStore {
        var items: [String: AlertSegment]
        var order: [String]

        init(items: [String: AlertSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertSegment) {
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

        func list() -> [AlertSegment] {
            var out: [AlertSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertSegmentStore() -> any AlertSegmentStore {
        return MemoryAlertSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertSegmentStore: AlertSegmentStore {
        var inner: MemoryAlertSegmentStore
        var cache: TTLCache<AlertSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertSegmentStore, cache: TTLCache<AlertSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertSegment? {
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

        func save(_ item: AlertSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertSegment] {
            return inner.list()
        }
    }

    static func newCachedAlertSegmentStore(_ inner: MemoryAlertSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertSegmentStore {
        return CachedAlertSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert segments. Empty fields match all.
    final class AlertSegmentQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertSegment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertSegment]) -> [AlertSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertSegments(_ store: any AlertSegmentStore, query: AlertSegmentQuery) -> [AlertSegment] {
        return query.apply(store.list())
    }
}

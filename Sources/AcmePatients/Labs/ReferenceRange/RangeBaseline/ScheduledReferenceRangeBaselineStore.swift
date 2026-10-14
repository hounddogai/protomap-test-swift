import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled reference range baselines by code.
    protocol ScheduledReferenceRangeBaselineStore {
        func find(_ code: String) -> ScheduledReferenceRangeBaseline?
        func save(_ item: ScheduledReferenceRangeBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReferenceRangeBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReferenceRangeBaselineStore: ScheduledReferenceRangeBaselineStore {
        var items: [String: ScheduledReferenceRangeBaseline]
        var order: [String]

        init(items: [String: ScheduledReferenceRangeBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReferenceRangeBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReferenceRangeBaseline) {
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

        func list() -> [ScheduledReferenceRangeBaseline] {
            var out: [ScheduledReferenceRangeBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReferenceRangeBaselineStore() -> any ScheduledReferenceRangeBaselineStore {
        return MemoryScheduledReferenceRangeBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReferenceRangeBaselineStore: ScheduledReferenceRangeBaselineStore {
        var inner: MemoryScheduledReferenceRangeBaselineStore
        var cache: TTLCache<ScheduledReferenceRangeBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReferenceRangeBaselineStore, cache: TTLCache<ScheduledReferenceRangeBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReferenceRangeBaseline? {
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

        func save(_ item: ScheduledReferenceRangeBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReferenceRangeBaseline] {
            return inner.list()
        }
    }

    static func newCachedScheduledReferenceRangeBaselineStore(_ inner: MemoryScheduledReferenceRangeBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReferenceRangeBaselineStore {
        return CachedScheduledReferenceRangeBaselineStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled reference range baselines. Empty fields match all.
    final class ScheduledReferenceRangeBaselineQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReferenceRangeBaseline) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReferenceRangeBaseline]) -> [ScheduledReferenceRangeBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReferenceRangeBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReferenceRangeBaselines(_ store: any ScheduledReferenceRangeBaselineStore, query: ScheduledReferenceRangeBaselineQuery) -> [ScheduledReferenceRangeBaseline] {
        return query.apply(store.list())
    }
}

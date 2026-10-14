import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled accession targets by code.
    protocol ScheduledAccessionTargetStore {
        func find(_ code: String) -> ScheduledAccessionTarget?
        func save(_ item: ScheduledAccessionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAccessionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAccessionTargetStore: ScheduledAccessionTargetStore {
        var items: [String: ScheduledAccessionTarget]
        var order: [String]

        init(items: [String: ScheduledAccessionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAccessionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAccessionTarget) {
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

        func list() -> [ScheduledAccessionTarget] {
            var out: [ScheduledAccessionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAccessionTargetStore() -> any ScheduledAccessionTargetStore {
        return MemoryScheduledAccessionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAccessionTargetStore: ScheduledAccessionTargetStore {
        var inner: MemoryScheduledAccessionTargetStore
        var cache: TTLCache<ScheduledAccessionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAccessionTargetStore, cache: TTLCache<ScheduledAccessionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAccessionTarget? {
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

        func save(_ item: ScheduledAccessionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAccessionTarget] {
            return inner.list()
        }
    }

    static func newCachedScheduledAccessionTargetStore(_ inner: MemoryScheduledAccessionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAccessionTargetStore {
        return CachedScheduledAccessionTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled accession targets. Empty fields match all.
    final class ScheduledAccessionTargetQuery {
        var segment: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAccessionTarget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [ScheduledAccessionTarget]) -> [ScheduledAccessionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAccessionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAccessionTargets(_ store: any ScheduledAccessionTargetStore, query: ScheduledAccessionTargetQuery) -> [ScheduledAccessionTarget] {
        return query.apply(store.list())
    }
}

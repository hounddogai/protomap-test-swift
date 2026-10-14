import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach targets by code.
    protocol OutreachTargetStore {
        func find(_ code: String) -> OutreachTarget?
        func save(_ item: OutreachTarget)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachTargetStore: OutreachTargetStore {
        var items: [String: OutreachTarget]
        var order: [String]

        init(items: [String: OutreachTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachTarget) {
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

        func list() -> [OutreachTarget] {
            var out: [OutreachTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachTargetStore() -> any OutreachTargetStore {
        return MemoryOutreachTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachTargetStore: OutreachTargetStore {
        var inner: MemoryOutreachTargetStore
        var cache: TTLCache<OutreachTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachTargetStore, cache: TTLCache<OutreachTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachTarget? {
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

        func save(_ item: OutreachTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachTarget] {
            return inner.list()
        }
    }

    static func newCachedOutreachTargetStore(_ inner: MemoryOutreachTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachTargetStore {
        return CachedOutreachTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach targets. Empty fields match all.
    final class OutreachTargetQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachTarget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachTarget]) -> [OutreachTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachTargets(_ store: any OutreachTargetStore, query: OutreachTargetQuery) -> [OutreachTarget] {
        return query.apply(store.list())
    }
}

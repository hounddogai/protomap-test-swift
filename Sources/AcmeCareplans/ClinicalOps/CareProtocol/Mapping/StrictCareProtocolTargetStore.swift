import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict care protocol targets by code.
    protocol StrictCareProtocolTargetStore {
        func find(_ code: String) -> StrictCareProtocolTarget?
        func save(_ item: StrictCareProtocolTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCareProtocolTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCareProtocolTargetStore: StrictCareProtocolTargetStore {
        var items: [String: StrictCareProtocolTarget]
        var order: [String]

        init(items: [String: StrictCareProtocolTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCareProtocolTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCareProtocolTarget) {
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

        func list() -> [StrictCareProtocolTarget] {
            var out: [StrictCareProtocolTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCareProtocolTargetStore() -> any StrictCareProtocolTargetStore {
        return MemoryStrictCareProtocolTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCareProtocolTargetStore: StrictCareProtocolTargetStore {
        var inner: MemoryStrictCareProtocolTargetStore
        var cache: TTLCache<StrictCareProtocolTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCareProtocolTargetStore, cache: TTLCache<StrictCareProtocolTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCareProtocolTarget? {
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

        func save(_ item: StrictCareProtocolTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCareProtocolTarget] {
            return inner.list()
        }
    }

    static func newCachedStrictCareProtocolTargetStore(_ inner: MemoryStrictCareProtocolTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCareProtocolTargetStore {
        return CachedStrictCareProtocolTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict care protocol targets. Empty fields match all.
    final class StrictCareProtocolTargetQuery {
        var label: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCareProtocolTarget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictCareProtocolTarget]) -> [StrictCareProtocolTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCareProtocolTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCareProtocolTargets(_ store: any StrictCareProtocolTargetStore, query: StrictCareProtocolTargetQuery) -> [StrictCareProtocolTarget] {
        return query.apply(store.list())
    }
}

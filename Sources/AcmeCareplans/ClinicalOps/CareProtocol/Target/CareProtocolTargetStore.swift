import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol targets by code.
    protocol CareProtocolTargetStore {
        func find(_ code: String) -> CareProtocolTarget?
        func save(_ item: CareProtocolTarget)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolTargetStore: CareProtocolTargetStore {
        var items: [String: CareProtocolTarget]
        var order: [String]

        init(items: [String: CareProtocolTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolTarget) {
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

        func list() -> [CareProtocolTarget] {
            var out: [CareProtocolTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolTargetStore() -> any CareProtocolTargetStore {
        return MemoryCareProtocolTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolTargetStore: CareProtocolTargetStore {
        var inner: MemoryCareProtocolTargetStore
        var cache: TTLCache<CareProtocolTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolTargetStore, cache: TTLCache<CareProtocolTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolTarget? {
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

        func save(_ item: CareProtocolTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolTarget] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolTargetStore(_ inner: MemoryCareProtocolTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolTargetStore {
        return CachedCareProtocolTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol targets. Empty fields match all.
    final class CareProtocolTargetQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolTarget]) -> [CareProtocolTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolTargets(_ store: any CareProtocolTargetStore, query: CareProtocolTargetQuery) -> [CareProtocolTarget] {
        return query.apply(store.list())
    }
}

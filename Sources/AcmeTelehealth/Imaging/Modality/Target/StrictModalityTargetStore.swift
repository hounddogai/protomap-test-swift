import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict modality targets by code.
    protocol StrictModalityTargetStore {
        func find(_ code: String) -> StrictModalityTarget?
        func save(_ item: StrictModalityTarget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictModalityTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictModalityTargetStore: StrictModalityTargetStore {
        var items: [String: StrictModalityTarget]
        var order: [String]

        init(items: [String: StrictModalityTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictModalityTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictModalityTarget) {
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

        func list() -> [StrictModalityTarget] {
            var out: [StrictModalityTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictModalityTargetStore() -> any StrictModalityTargetStore {
        return MemoryStrictModalityTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictModalityTargetStore: StrictModalityTargetStore {
        var inner: MemoryStrictModalityTargetStore
        var cache: TTLCache<StrictModalityTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictModalityTargetStore, cache: TTLCache<StrictModalityTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictModalityTarget? {
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

        func save(_ item: StrictModalityTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictModalityTarget] {
            return inner.list()
        }
    }

    static func newCachedStrictModalityTargetStore(_ inner: MemoryStrictModalityTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictModalityTargetStore {
        return CachedStrictModalityTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict modality targets. Empty fields match all.
    final class StrictModalityTargetQuery {
        var category: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictModalityTarget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [StrictModalityTarget]) -> [StrictModalityTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictModalityTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictModalityTargets(_ store: any StrictModalityTargetStore, query: StrictModalityTargetQuery) -> [StrictModalityTarget] {
        return query.apply(store.list())
    }
}

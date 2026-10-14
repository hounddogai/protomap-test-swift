import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff targets by code.
    protocol HandoffTargetStore {
        func find(_ code: String) -> HandoffTarget?
        func save(_ item: HandoffTarget)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffTargetStore: HandoffTargetStore {
        var items: [String: HandoffTarget]
        var order: [String]

        init(items: [String: HandoffTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffTarget) {
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

        func list() -> [HandoffTarget] {
            var out: [HandoffTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffTargetStore() -> any HandoffTargetStore {
        return MemoryHandoffTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffTargetStore: HandoffTargetStore {
        var inner: MemoryHandoffTargetStore
        var cache: TTLCache<HandoffTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffTargetStore, cache: TTLCache<HandoffTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffTarget? {
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

        func save(_ item: HandoffTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffTarget] {
            return inner.list()
        }
    }

    static func newCachedHandoffTargetStore(_ inner: MemoryHandoffTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffTargetStore {
        return CachedHandoffTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff targets. Empty fields match all.
    final class HandoffTargetQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffTarget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [HandoffTarget]) -> [HandoffTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffTargets(_ store: any HandoffTargetStore, query: HandoffTargetQuery) -> [HandoffTarget] {
        return query.apply(store.list())
    }
}

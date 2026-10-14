import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual handoff targets by code.
    protocol ManualHandoffTargetStore {
        func find(_ code: String) -> ManualHandoffTarget?
        func save(_ item: ManualHandoffTarget)
        func remove(_ code: String) -> Bool
        func list() -> [ManualHandoffTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualHandoffTargetStore: ManualHandoffTargetStore {
        var items: [String: ManualHandoffTarget]
        var order: [String]

        init(items: [String: ManualHandoffTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualHandoffTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualHandoffTarget) {
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

        func list() -> [ManualHandoffTarget] {
            var out: [ManualHandoffTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualHandoffTargetStore() -> any ManualHandoffTargetStore {
        return MemoryManualHandoffTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualHandoffTargetStore: ManualHandoffTargetStore {
        var inner: MemoryManualHandoffTargetStore
        var cache: TTLCache<ManualHandoffTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualHandoffTargetStore, cache: TTLCache<ManualHandoffTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualHandoffTarget? {
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

        func save(_ item: ManualHandoffTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualHandoffTarget] {
            return inner.list()
        }
    }

    static func newCachedManualHandoffTargetStore(_ inner: MemoryManualHandoffTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualHandoffTargetStore {
        return CachedManualHandoffTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual handoff targets. Empty fields match all.
    final class ManualHandoffTargetQuery {
        var channel: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualHandoffTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualHandoffTarget]) -> [ManualHandoffTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualHandoffTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualHandoffTargets(_ store: any ManualHandoffTargetStore, query: ManualHandoffTargetQuery) -> [ManualHandoffTarget] {
        return query.apply(store.list())
    }
}

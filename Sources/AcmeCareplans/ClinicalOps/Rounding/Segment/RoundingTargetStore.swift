import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding targets by code.
    protocol RoundingTargetStore {
        func find(_ code: String) -> RoundingTarget?
        func save(_ item: RoundingTarget)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingTargetStore: RoundingTargetStore {
        var items: [String: RoundingTarget]
        var order: [String]

        init(items: [String: RoundingTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingTarget) {
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

        func list() -> [RoundingTarget] {
            var out: [RoundingTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingTargetStore() -> any RoundingTargetStore {
        return MemoryRoundingTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingTargetStore: RoundingTargetStore {
        var inner: MemoryRoundingTargetStore
        var cache: TTLCache<RoundingTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingTargetStore, cache: TTLCache<RoundingTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingTarget? {
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

        func save(_ item: RoundingTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingTarget] {
            return inner.list()
        }
    }

    static func newCachedRoundingTargetStore(_ inner: MemoryRoundingTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingTargetStore {
        return CachedRoundingTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding targets. Empty fields match all.
    final class RoundingTargetQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingTarget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingTarget]) -> [RoundingTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingTargets(_ store: any RoundingTargetStore, query: RoundingTargetQuery) -> [RoundingTarget] {
        return query.apply(store.list())
    }
}

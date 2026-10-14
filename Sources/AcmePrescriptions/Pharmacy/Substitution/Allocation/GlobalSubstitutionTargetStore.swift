import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global substitution targets by code.
    protocol GlobalSubstitutionTargetStore {
        func find(_ code: String) -> GlobalSubstitutionTarget?
        func save(_ item: GlobalSubstitutionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSubstitutionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSubstitutionTargetStore: GlobalSubstitutionTargetStore {
        var items: [String: GlobalSubstitutionTarget]
        var order: [String]

        init(items: [String: GlobalSubstitutionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSubstitutionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSubstitutionTarget) {
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

        func list() -> [GlobalSubstitutionTarget] {
            var out: [GlobalSubstitutionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSubstitutionTargetStore() -> any GlobalSubstitutionTargetStore {
        return MemoryGlobalSubstitutionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSubstitutionTargetStore: GlobalSubstitutionTargetStore {
        var inner: MemoryGlobalSubstitutionTargetStore
        var cache: TTLCache<GlobalSubstitutionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSubstitutionTargetStore, cache: TTLCache<GlobalSubstitutionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSubstitutionTarget? {
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

        func save(_ item: GlobalSubstitutionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSubstitutionTarget] {
            return inner.list()
        }
    }

    static func newCachedGlobalSubstitutionTargetStore(_ inner: MemoryGlobalSubstitutionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSubstitutionTargetStore {
        return CachedGlobalSubstitutionTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global substitution targets. Empty fields match all.
    final class GlobalSubstitutionTargetQuery {
        var segment: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minScore: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSubstitutionTarget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSubstitutionTarget]) -> [GlobalSubstitutionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSubstitutionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSubstitutionTargets(_ store: any GlobalSubstitutionTargetStore, query: GlobalSubstitutionTargetQuery) -> [GlobalSubstitutionTarget] {
        return query.apply(store.list())
    }
}

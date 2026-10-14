import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution targets by code.
    protocol SubstitutionTargetStore {
        func find(_ code: String) -> SubstitutionTarget?
        func save(_ item: SubstitutionTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionTargetStore: SubstitutionTargetStore {
        var items: [String: SubstitutionTarget]
        var order: [String]

        init(items: [String: SubstitutionTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionTarget) {
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

        func list() -> [SubstitutionTarget] {
            var out: [SubstitutionTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionTargetStore() -> any SubstitutionTargetStore {
        return MemorySubstitutionTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionTargetStore: SubstitutionTargetStore {
        var inner: MemorySubstitutionTargetStore
        var cache: TTLCache<SubstitutionTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionTargetStore, cache: TTLCache<SubstitutionTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionTarget? {
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

        func save(_ item: SubstitutionTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionTarget] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionTargetStore(_ inner: MemorySubstitutionTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionTargetStore {
        return CachedSubstitutionTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution targets. Empty fields match all.
    final class SubstitutionTargetQuery {
        var name: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minSequence: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [SubstitutionTarget]) -> [SubstitutionTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionTargets(_ store: any SubstitutionTargetStore, query: SubstitutionTargetQuery) -> [SubstitutionTarget] {
        return query.apply(store.list())
    }
}

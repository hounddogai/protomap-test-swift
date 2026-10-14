import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient census targets by code.
    protocol LenientCensusTargetStore {
        func find(_ code: String) -> LenientCensusTarget?
        func save(_ item: LenientCensusTarget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCensusTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCensusTargetStore: LenientCensusTargetStore {
        var items: [String: LenientCensusTarget]
        var order: [String]

        init(items: [String: LenientCensusTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCensusTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCensusTarget) {
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

        func list() -> [LenientCensusTarget] {
            var out: [LenientCensusTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCensusTargetStore() -> any LenientCensusTargetStore {
        return MemoryLenientCensusTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCensusTargetStore: LenientCensusTargetStore {
        var inner: MemoryLenientCensusTargetStore
        var cache: TTLCache<LenientCensusTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCensusTargetStore, cache: TTLCache<LenientCensusTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCensusTarget? {
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

        func save(_ item: LenientCensusTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCensusTarget] {
            return inner.list()
        }
    }

    static func newCachedLenientCensusTargetStore(_ inner: MemoryLenientCensusTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCensusTargetStore {
        return CachedLenientCensusTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient census targets. Empty fields match all.
    final class LenientCensusTargetQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCensusTarget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCensusTarget]) -> [LenientCensusTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCensusTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCensusTargets(_ store: any LenientCensusTargetStore, query: LenientCensusTargetQuery) -> [LenientCensusTarget] {
        return query.apply(store.list())
    }
}

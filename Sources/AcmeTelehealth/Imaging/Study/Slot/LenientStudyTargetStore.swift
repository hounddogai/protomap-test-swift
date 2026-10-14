import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient study targets by code.
    protocol LenientStudyTargetStore {
        func find(_ code: String) -> LenientStudyTarget?
        func save(_ item: LenientStudyTarget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientStudyTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientStudyTargetStore: LenientStudyTargetStore {
        var items: [String: LenientStudyTarget]
        var order: [String]

        init(items: [String: LenientStudyTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientStudyTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientStudyTarget) {
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

        func list() -> [LenientStudyTarget] {
            var out: [LenientStudyTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientStudyTargetStore() -> any LenientStudyTargetStore {
        return MemoryLenientStudyTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientStudyTargetStore: LenientStudyTargetStore {
        var inner: MemoryLenientStudyTargetStore
        var cache: TTLCache<LenientStudyTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientStudyTargetStore, cache: TTLCache<LenientStudyTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientStudyTarget? {
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

        func save(_ item: LenientStudyTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientStudyTarget] {
            return inner.list()
        }
    }

    static func newCachedLenientStudyTargetStore(_ inner: MemoryLenientStudyTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientStudyTargetStore {
        return CachedLenientStudyTargetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient study targets. Empty fields match all.
    final class LenientStudyTargetQuery {
        var name: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientStudyTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientStudyTarget]) -> [LenientStudyTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientStudyTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientStudyTargets(_ store: any LenientStudyTargetStore, query: LenientStudyTargetQuery) -> [LenientStudyTarget] {
        return query.apply(store.list())
    }
}

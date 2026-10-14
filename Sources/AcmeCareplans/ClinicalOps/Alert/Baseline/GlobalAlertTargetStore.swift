import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global alert targets by code.
    protocol GlobalAlertTargetStore {
        func find(_ code: String) -> GlobalAlertTarget?
        func save(_ item: GlobalAlertTarget)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAlertTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAlertTargetStore: GlobalAlertTargetStore {
        var items: [String: GlobalAlertTarget]
        var order: [String]

        init(items: [String: GlobalAlertTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAlertTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAlertTarget) {
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

        func list() -> [GlobalAlertTarget] {
            var out: [GlobalAlertTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAlertTargetStore() -> any GlobalAlertTargetStore {
        return MemoryGlobalAlertTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAlertTargetStore: GlobalAlertTargetStore {
        var inner: MemoryGlobalAlertTargetStore
        var cache: TTLCache<GlobalAlertTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAlertTargetStore, cache: TTLCache<GlobalAlertTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAlertTarget? {
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

        func save(_ item: GlobalAlertTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAlertTarget] {
            return inner.list()
        }
    }

    static func newCachedGlobalAlertTargetStore(_ inner: MemoryGlobalAlertTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAlertTargetStore {
        return CachedGlobalAlertTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global alert targets. Empty fields match all.
    final class GlobalAlertTargetQuery {
        var source: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minSequence: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAlertTarget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [GlobalAlertTarget]) -> [GlobalAlertTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAlertTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAlertTargets(_ store: any GlobalAlertTargetStore, query: GlobalAlertTargetQuery) -> [GlobalAlertTarget] {
        return query.apply(store.list())
    }
}

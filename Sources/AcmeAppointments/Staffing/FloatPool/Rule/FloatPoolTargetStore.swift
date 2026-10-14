import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool targets by code.
    protocol FloatPoolTargetStore {
        func find(_ code: String) -> FloatPoolTarget?
        func save(_ item: FloatPoolTarget)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolTargetStore: FloatPoolTargetStore {
        var items: [String: FloatPoolTarget]
        var order: [String]

        init(items: [String: FloatPoolTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolTarget) {
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

        func list() -> [FloatPoolTarget] {
            var out: [FloatPoolTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolTargetStore() -> any FloatPoolTargetStore {
        return MemoryFloatPoolTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolTargetStore: FloatPoolTargetStore {
        var inner: MemoryFloatPoolTargetStore
        var cache: TTLCache<FloatPoolTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolTargetStore, cache: TTLCache<FloatPoolTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolTarget? {
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

        func save(_ item: FloatPoolTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolTarget] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolTargetStore(_ inner: MemoryFloatPoolTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolTargetStore {
        return CachedFloatPoolTargetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool targets. Empty fields match all.
    final class FloatPoolTargetQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolTarget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolTarget]) -> [FloatPoolTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolTargets(_ store: any FloatPoolTargetStore, query: FloatPoolTargetQuery) -> [FloatPoolTarget] {
        return query.apply(store.list())
    }
}

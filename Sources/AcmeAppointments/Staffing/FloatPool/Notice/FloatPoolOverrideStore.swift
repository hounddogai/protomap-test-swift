import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool overrides by code.
    protocol FloatPoolOverrideStore {
        func find(_ code: String) -> FloatPoolOverride?
        func save(_ item: FloatPoolOverride)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolOverrideStore: FloatPoolOverrideStore {
        var items: [String: FloatPoolOverride]
        var order: [String]

        init(items: [String: FloatPoolOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolOverride) {
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

        func list() -> [FloatPoolOverride] {
            var out: [FloatPoolOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolOverrideStore() -> any FloatPoolOverrideStore {
        return MemoryFloatPoolOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolOverrideStore: FloatPoolOverrideStore {
        var inner: MemoryFloatPoolOverrideStore
        var cache: TTLCache<FloatPoolOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolOverrideStore, cache: TTLCache<FloatPoolOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolOverride? {
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

        func save(_ item: FloatPoolOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolOverride] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolOverrideStore(_ inner: MemoryFloatPoolOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolOverrideStore {
        return CachedFloatPoolOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool overrides. Empty fields match all.
    final class FloatPoolOverrideQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolOverride) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolOverride]) -> [FloatPoolOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolOverrides(_ store: any FloatPoolOverrideStore, query: FloatPoolOverrideQuery) -> [FloatPoolOverride] {
        return query.apply(store.list())
    }
}

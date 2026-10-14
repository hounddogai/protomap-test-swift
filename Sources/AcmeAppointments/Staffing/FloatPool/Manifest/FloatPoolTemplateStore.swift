import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool templates by code.
    protocol FloatPoolTemplateStore {
        func find(_ code: String) -> FloatPoolTemplate?
        func save(_ item: FloatPoolTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolTemplateStore: FloatPoolTemplateStore {
        var items: [String: FloatPoolTemplate]
        var order: [String]

        init(items: [String: FloatPoolTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolTemplate) {
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

        func list() -> [FloatPoolTemplate] {
            var out: [FloatPoolTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolTemplateStore() -> any FloatPoolTemplateStore {
        return MemoryFloatPoolTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolTemplateStore: FloatPoolTemplateStore {
        var inner: MemoryFloatPoolTemplateStore
        var cache: TTLCache<FloatPoolTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolTemplateStore, cache: TTLCache<FloatPoolTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolTemplate? {
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

        func save(_ item: FloatPoolTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolTemplate] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolTemplateStore(_ inner: MemoryFloatPoolTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolTemplateStore {
        return CachedFloatPoolTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool templates. Empty fields match all.
    final class FloatPoolTemplateQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolTemplate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolTemplate]) -> [FloatPoolTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolTemplates(_ store: any FloatPoolTemplateStore, query: FloatPoolTemplateQuery) -> [FloatPoolTemplate] {
        return query.apply(store.list())
    }
}

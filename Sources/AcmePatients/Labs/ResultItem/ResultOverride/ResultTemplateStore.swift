import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result templates by code.
    protocol ResultTemplateStore {
        func find(_ code: String) -> ResultTemplate?
        func save(_ item: ResultTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ResultTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultTemplateStore: ResultTemplateStore {
        var items: [String: ResultTemplate]
        var order: [String]

        init(items: [String: ResultTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultTemplate) {
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

        func list() -> [ResultTemplate] {
            var out: [ResultTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultTemplateStore() -> any ResultTemplateStore {
        return MemoryResultTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultTemplateStore: ResultTemplateStore {
        var inner: MemoryResultTemplateStore
        var cache: TTLCache<ResultTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultTemplateStore, cache: TTLCache<ResultTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultTemplate? {
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

        func save(_ item: ResultTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultTemplate] {
            return inner.list()
        }
    }

    static func newCachedResultTemplateStore(_ inner: MemoryResultTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultTemplateStore {
        return CachedResultTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result templates. Empty fields match all.
    final class ResultTemplateQuery {
        var segment: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minRate: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultTemplate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultTemplate]) -> [ResultTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultTemplates(_ store: any ResultTemplateStore, query: ResultTemplateQuery) -> [ResultTemplate] {
        return query.apply(store.list())
    }
}

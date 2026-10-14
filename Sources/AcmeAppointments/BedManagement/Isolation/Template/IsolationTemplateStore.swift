import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation templates by code.
    protocol IsolationTemplateStore {
        func find(_ code: String) -> IsolationTemplate?
        func save(_ item: IsolationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationTemplateStore: IsolationTemplateStore {
        var items: [String: IsolationTemplate]
        var order: [String]

        init(items: [String: IsolationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationTemplate) {
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

        func list() -> [IsolationTemplate] {
            var out: [IsolationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationTemplateStore() -> any IsolationTemplateStore {
        return MemoryIsolationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationTemplateStore: IsolationTemplateStore {
        var inner: MemoryIsolationTemplateStore
        var cache: TTLCache<IsolationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationTemplateStore, cache: TTLCache<IsolationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationTemplate? {
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

        func save(_ item: IsolationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationTemplate] {
            return inner.list()
        }
    }

    static func newCachedIsolationTemplateStore(_ inner: MemoryIsolationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationTemplateStore {
        return CachedIsolationTemplateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation templates. Empty fields match all.
    final class IsolationTemplateQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationTemplate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [IsolationTemplate]) -> [IsolationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationTemplates(_ store: any IsolationTemplateStore, query: IsolationTemplateQuery) -> [IsolationTemplate] {
        return query.apply(store.list())
    }
}

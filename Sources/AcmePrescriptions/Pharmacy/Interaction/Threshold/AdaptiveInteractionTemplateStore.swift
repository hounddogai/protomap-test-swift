import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive interaction templates by code.
    protocol AdaptiveInteractionTemplateStore {
        func find(_ code: String) -> AdaptiveInteractionTemplate?
        func save(_ item: AdaptiveInteractionTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInteractionTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInteractionTemplateStore: AdaptiveInteractionTemplateStore {
        var items: [String: AdaptiveInteractionTemplate]
        var order: [String]

        init(items: [String: AdaptiveInteractionTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInteractionTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInteractionTemplate) {
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

        func list() -> [AdaptiveInteractionTemplate] {
            var out: [AdaptiveInteractionTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInteractionTemplateStore() -> any AdaptiveInteractionTemplateStore {
        return MemoryAdaptiveInteractionTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInteractionTemplateStore: AdaptiveInteractionTemplateStore {
        var inner: MemoryAdaptiveInteractionTemplateStore
        var cache: TTLCache<AdaptiveInteractionTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInteractionTemplateStore, cache: TTLCache<AdaptiveInteractionTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInteractionTemplate? {
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

        func save(_ item: AdaptiveInteractionTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInteractionTemplate] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInteractionTemplateStore(_ inner: MemoryAdaptiveInteractionTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInteractionTemplateStore {
        return CachedAdaptiveInteractionTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive interaction templates. Empty fields match all.
    final class AdaptiveInteractionTemplateQuery {
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

        func matches(_ item: AdaptiveInteractionTemplate) -> Bool {
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

        func apply(_ items: [AdaptiveInteractionTemplate]) -> [AdaptiveInteractionTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInteractionTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInteractionTemplates(_ store: any AdaptiveInteractionTemplateStore, query: AdaptiveInteractionTemplateQuery) -> [AdaptiveInteractionTemplate] {
        return query.apply(store.list())
    }
}

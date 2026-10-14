import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered formulary templates by code.
    protocol TieredFormularyTemplateStore {
        func find(_ code: String) -> TieredFormularyTemplate?
        func save(_ item: TieredFormularyTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFormularyTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFormularyTemplateStore: TieredFormularyTemplateStore {
        var items: [String: TieredFormularyTemplate]
        var order: [String]

        init(items: [String: TieredFormularyTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFormularyTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFormularyTemplate) {
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

        func list() -> [TieredFormularyTemplate] {
            var out: [TieredFormularyTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFormularyTemplateStore() -> any TieredFormularyTemplateStore {
        return MemoryTieredFormularyTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFormularyTemplateStore: TieredFormularyTemplateStore {
        var inner: MemoryTieredFormularyTemplateStore
        var cache: TTLCache<TieredFormularyTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFormularyTemplateStore, cache: TTLCache<TieredFormularyTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFormularyTemplate? {
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

        func save(_ item: TieredFormularyTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFormularyTemplate] {
            return inner.list()
        }
    }

    static func newCachedTieredFormularyTemplateStore(_ inner: MemoryTieredFormularyTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFormularyTemplateStore {
        return CachedTieredFormularyTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered formulary templates. Empty fields match all.
    final class TieredFormularyTemplateQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFormularyTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredFormularyTemplate]) -> [TieredFormularyTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFormularyTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFormularyTemplates(_ store: any TieredFormularyTemplateStore, query: TieredFormularyTemplateQuery) -> [TieredFormularyTemplate] {
        return query.apply(store.list())
    }
}

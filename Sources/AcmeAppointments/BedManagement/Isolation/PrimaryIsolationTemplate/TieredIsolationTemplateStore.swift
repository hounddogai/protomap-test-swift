import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps tiered isolation templates by code.
    protocol TieredIsolationTemplateStore {
        func find(_ code: String) -> TieredIsolationTemplate?
        func save(_ item: TieredIsolationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [TieredIsolationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredIsolationTemplateStore: TieredIsolationTemplateStore {
        var items: [String: TieredIsolationTemplate]
        var order: [String]

        init(items: [String: TieredIsolationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredIsolationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredIsolationTemplate) {
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

        func list() -> [TieredIsolationTemplate] {
            var out: [TieredIsolationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredIsolationTemplateStore() -> any TieredIsolationTemplateStore {
        return MemoryTieredIsolationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredIsolationTemplateStore: TieredIsolationTemplateStore {
        var inner: MemoryTieredIsolationTemplateStore
        var cache: TTLCache<TieredIsolationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredIsolationTemplateStore, cache: TTLCache<TieredIsolationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredIsolationTemplate? {
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

        func save(_ item: TieredIsolationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredIsolationTemplate] {
            return inner.list()
        }
    }

    static func newCachedTieredIsolationTemplateStore(_ inner: MemoryTieredIsolationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredIsolationTemplateStore {
        return CachedTieredIsolationTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered isolation templates. Empty fields match all.
    final class TieredIsolationTemplateQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredIsolationTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredIsolationTemplate]) -> [TieredIsolationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredIsolationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredIsolationTemplates(_ store: any TieredIsolationTemplateStore, query: TieredIsolationTemplateQuery) -> [TieredIsolationTemplate] {
        return query.apply(store.list())
    }
}

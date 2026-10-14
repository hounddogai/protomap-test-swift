import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance templates by code.
    protocol TieredRemittanceTemplateStore {
        func find(_ code: String) -> TieredRemittanceTemplate?
        func save(_ item: TieredRemittanceTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceTemplateStore: TieredRemittanceTemplateStore {
        var items: [String: TieredRemittanceTemplate]
        var order: [String]

        init(items: [String: TieredRemittanceTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceTemplate) {
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

        func list() -> [TieredRemittanceTemplate] {
            var out: [TieredRemittanceTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceTemplateStore() -> any TieredRemittanceTemplateStore {
        return MemoryTieredRemittanceTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceTemplateStore: TieredRemittanceTemplateStore {
        var inner: MemoryTieredRemittanceTemplateStore
        var cache: TTLCache<TieredRemittanceTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceTemplateStore, cache: TTLCache<TieredRemittanceTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceTemplate? {
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

        func save(_ item: TieredRemittanceTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceTemplate] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceTemplateStore(_ inner: MemoryTieredRemittanceTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceTemplateStore {
        return CachedTieredRemittanceTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance templates. Empty fields match all.
    final class TieredRemittanceTemplateQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRemittanceTemplate]) -> [TieredRemittanceTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceTemplates(_ store: any TieredRemittanceTemplateStore, query: TieredRemittanceTemplateQuery) -> [TieredRemittanceTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default remittance templates by code.
    protocol DefaultRemittanceTemplateStore {
        func find(_ code: String) -> DefaultRemittanceTemplate?
        func save(_ item: DefaultRemittanceTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultRemittanceTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultRemittanceTemplateStore: DefaultRemittanceTemplateStore {
        var items: [String: DefaultRemittanceTemplate]
        var order: [String]

        init(items: [String: DefaultRemittanceTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultRemittanceTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultRemittanceTemplate) {
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

        func list() -> [DefaultRemittanceTemplate] {
            var out: [DefaultRemittanceTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultRemittanceTemplateStore() -> any DefaultRemittanceTemplateStore {
        return MemoryDefaultRemittanceTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultRemittanceTemplateStore: DefaultRemittanceTemplateStore {
        var inner: MemoryDefaultRemittanceTemplateStore
        var cache: TTLCache<DefaultRemittanceTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultRemittanceTemplateStore, cache: TTLCache<DefaultRemittanceTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultRemittanceTemplate? {
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

        func save(_ item: DefaultRemittanceTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultRemittanceTemplate] {
            return inner.list()
        }
    }

    static func newCachedDefaultRemittanceTemplateStore(_ inner: MemoryDefaultRemittanceTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultRemittanceTemplateStore {
        return CachedDefaultRemittanceTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default remittance templates. Empty fields match all.
    final class DefaultRemittanceTemplateQuery {
        var label: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultRemittanceTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultRemittanceTemplate]) -> [DefaultRemittanceTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultRemittanceTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultRemittanceTemplates(_ store: any DefaultRemittanceTemplateStore, query: DefaultRemittanceTemplateQuery) -> [DefaultRemittanceTemplate] {
        return query.apply(store.list())
    }
}

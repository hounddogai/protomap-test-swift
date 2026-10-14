import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance templates by code.
    protocol RemittanceTemplateStore {
        func find(_ code: String) -> RemittanceTemplate?
        func save(_ item: RemittanceTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceTemplateStore: RemittanceTemplateStore {
        var items: [String: RemittanceTemplate]
        var order: [String]

        init(items: [String: RemittanceTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceTemplate) {
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

        func list() -> [RemittanceTemplate] {
            var out: [RemittanceTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceTemplateStore() -> any RemittanceTemplateStore {
        return MemoryRemittanceTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceTemplateStore: RemittanceTemplateStore {
        var inner: MemoryRemittanceTemplateStore
        var cache: TTLCache<RemittanceTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceTemplateStore, cache: TTLCache<RemittanceTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceTemplate? {
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

        func save(_ item: RemittanceTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceTemplate] {
            return inner.list()
        }
    }

    static func newCachedRemittanceTemplateStore(_ inner: MemoryRemittanceTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceTemplateStore {
        return CachedRemittanceTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance templates. Empty fields match all.
    final class RemittanceTemplateQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceTemplate]) -> [RemittanceTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceTemplates(_ store: any RemittanceTemplateStore, query: RemittanceTemplateQuery) -> [RemittanceTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global consent form templates by code.
    protocol GlobalConsentFormTemplateStore {
        func find(_ code: String) -> GlobalConsentFormTemplate?
        func save(_ item: GlobalConsentFormTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalConsentFormTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalConsentFormTemplateStore: GlobalConsentFormTemplateStore {
        var items: [String: GlobalConsentFormTemplate]
        var order: [String]

        init(items: [String: GlobalConsentFormTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalConsentFormTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalConsentFormTemplate) {
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

        func list() -> [GlobalConsentFormTemplate] {
            var out: [GlobalConsentFormTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalConsentFormTemplateStore() -> any GlobalConsentFormTemplateStore {
        return MemoryGlobalConsentFormTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalConsentFormTemplateStore: GlobalConsentFormTemplateStore {
        var inner: MemoryGlobalConsentFormTemplateStore
        var cache: TTLCache<GlobalConsentFormTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalConsentFormTemplateStore, cache: TTLCache<GlobalConsentFormTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalConsentFormTemplate? {
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

        func save(_ item: GlobalConsentFormTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalConsentFormTemplate] {
            return inner.list()
        }
    }

    static func newCachedGlobalConsentFormTemplateStore(_ inner: MemoryGlobalConsentFormTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalConsentFormTemplateStore {
        return CachedGlobalConsentFormTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global consent form templates. Empty fields match all.
    final class GlobalConsentFormTemplateQuery {
        var facility: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRatio: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalConsentFormTemplate) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalConsentFormTemplate]) -> [GlobalConsentFormTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalConsentFormTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalConsentFormTemplates(_ store: any GlobalConsentFormTemplateStore, query: GlobalConsentFormTemplateQuery) -> [GlobalConsentFormTemplate] {
        return query.apply(store.list())
    }
}

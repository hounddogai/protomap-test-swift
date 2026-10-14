import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap templates by code.
    protocol CareGapTemplateStore {
        func find(_ code: String) -> CareGapTemplate?
        func save(_ item: CareGapTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapTemplateStore: CareGapTemplateStore {
        var items: [String: CareGapTemplate]
        var order: [String]

        init(items: [String: CareGapTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapTemplate) {
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

        func list() -> [CareGapTemplate] {
            var out: [CareGapTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapTemplateStore() -> any CareGapTemplateStore {
        return MemoryCareGapTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapTemplateStore: CareGapTemplateStore {
        var inner: MemoryCareGapTemplateStore
        var cache: TTLCache<CareGapTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapTemplateStore, cache: TTLCache<CareGapTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapTemplate? {
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

        func save(_ item: CareGapTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapTemplate] {
            return inner.list()
        }
    }

    static func newCachedCareGapTemplateStore(_ inner: MemoryCareGapTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapTemplateStore {
        return CachedCareGapTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap templates. Empty fields match all.
    final class CareGapTemplateQuery {
        var ward: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapTemplate]) -> [CareGapTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapTemplates(_ store: any CareGapTemplateStore, query: CareGapTemplateQuery) -> [CareGapTemplate] {
        return query.apply(store.list())
    }
}

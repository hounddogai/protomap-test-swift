import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual care protocol templates by code.
    protocol ManualCareProtocolTemplateStore {
        func find(_ code: String) -> ManualCareProtocolTemplate?
        func save(_ item: ManualCareProtocolTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolTemplateStore: ManualCareProtocolTemplateStore {
        var items: [String: ManualCareProtocolTemplate]
        var order: [String]

        init(items: [String: ManualCareProtocolTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolTemplate) {
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

        func list() -> [ManualCareProtocolTemplate] {
            var out: [ManualCareProtocolTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolTemplateStore() -> any ManualCareProtocolTemplateStore {
        return MemoryManualCareProtocolTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolTemplateStore: ManualCareProtocolTemplateStore {
        var inner: MemoryManualCareProtocolTemplateStore
        var cache: TTLCache<ManualCareProtocolTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolTemplateStore, cache: TTLCache<ManualCareProtocolTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolTemplate? {
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

        func save(_ item: ManualCareProtocolTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolTemplate] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolTemplateStore(_ inner: MemoryManualCareProtocolTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolTemplateStore {
        return CachedManualCareProtocolTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol templates. Empty fields match all.
    final class ManualCareProtocolTemplateQuery {
        var ward: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCareProtocolTemplate]) -> [ManualCareProtocolTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolTemplates(_ store: any ManualCareProtocolTemplateStore, query: ManualCareProtocolTemplateQuery) -> [ManualCareProtocolTemplate] {
        return query.apply(store.list())
    }
}

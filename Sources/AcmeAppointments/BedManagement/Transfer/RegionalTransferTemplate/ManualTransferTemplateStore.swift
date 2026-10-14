import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual transfer templates by code.
    protocol ManualTransferTemplateStore {
        func find(_ code: String) -> ManualTransferTemplate?
        func save(_ item: ManualTransferTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ManualTransferTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualTransferTemplateStore: ManualTransferTemplateStore {
        var items: [String: ManualTransferTemplate]
        var order: [String]

        init(items: [String: ManualTransferTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualTransferTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualTransferTemplate) {
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

        func list() -> [ManualTransferTemplate] {
            var out: [ManualTransferTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualTransferTemplateStore() -> any ManualTransferTemplateStore {
        return MemoryManualTransferTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualTransferTemplateStore: ManualTransferTemplateStore {
        var inner: MemoryManualTransferTemplateStore
        var cache: TTLCache<ManualTransferTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualTransferTemplateStore, cache: TTLCache<ManualTransferTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualTransferTemplate? {
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

        func save(_ item: ManualTransferTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualTransferTemplate] {
            return inner.list()
        }
    }

    static func newCachedManualTransferTemplateStore(_ inner: MemoryManualTransferTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualTransferTemplateStore {
        return CachedManualTransferTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual transfer templates. Empty fields match all.
    final class ManualTransferTemplateQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualTransferTemplate) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualTransferTemplate]) -> [ManualTransferTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualTransferTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualTransferTemplates(_ store: any ManualTransferTemplateStore, query: ManualTransferTemplateQuery) -> [ManualTransferTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered revocation templates by code.
    protocol TieredRevocationTemplateStore {
        func find(_ code: String) -> TieredRevocationTemplate?
        func save(_ item: TieredRevocationTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRevocationTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRevocationTemplateStore: TieredRevocationTemplateStore {
        var items: [String: TieredRevocationTemplate]
        var order: [String]

        init(items: [String: TieredRevocationTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRevocationTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRevocationTemplate) {
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

        func list() -> [TieredRevocationTemplate] {
            var out: [TieredRevocationTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRevocationTemplateStore() -> any TieredRevocationTemplateStore {
        return MemoryTieredRevocationTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRevocationTemplateStore: TieredRevocationTemplateStore {
        var inner: MemoryTieredRevocationTemplateStore
        var cache: TTLCache<TieredRevocationTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRevocationTemplateStore, cache: TTLCache<TieredRevocationTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRevocationTemplate? {
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

        func save(_ item: TieredRevocationTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRevocationTemplate] {
            return inner.list()
        }
    }

    static func newCachedTieredRevocationTemplateStore(_ inner: MemoryTieredRevocationTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRevocationTemplateStore {
        return CachedTieredRevocationTemplateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered revocation templates. Empty fields match all.
    final class TieredRevocationTemplateQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRevocationTemplate) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRevocationTemplate]) -> [TieredRevocationTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRevocationTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRevocationTemplates(_ store: any TieredRevocationTemplateStore, query: TieredRevocationTemplateQuery) -> [TieredRevocationTemplate] {
        return query.apply(store.list())
    }
}

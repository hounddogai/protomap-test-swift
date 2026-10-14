import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff mappings by code.
    protocol HandoffMappingStore {
        func find(_ code: String) -> HandoffMapping?
        func save(_ item: HandoffMapping)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffMappingStore: HandoffMappingStore {
        var items: [String: HandoffMapping]
        var order: [String]

        init(items: [String: HandoffMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffMapping) {
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

        func list() -> [HandoffMapping] {
            var out: [HandoffMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffMappingStore() -> any HandoffMappingStore {
        return MemoryHandoffMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffMappingStore: HandoffMappingStore {
        var inner: MemoryHandoffMappingStore
        var cache: TTLCache<HandoffMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffMappingStore, cache: TTLCache<HandoffMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffMapping? {
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

        func save(_ item: HandoffMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffMapping] {
            return inner.list()
        }
    }

    static func newCachedHandoffMappingStore(_ inner: MemoryHandoffMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffMappingStore {
        return CachedHandoffMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff mappings. Empty fields match all.
    final class HandoffMappingQuery {
        var region: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCopay: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffMapping) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [HandoffMapping]) -> [HandoffMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffMappings(_ store: any HandoffMappingStore, query: HandoffMappingQuery) -> [HandoffMapping] {
        return query.apply(store.list())
    }
}

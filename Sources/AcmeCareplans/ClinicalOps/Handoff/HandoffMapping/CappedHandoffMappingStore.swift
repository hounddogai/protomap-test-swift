import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped handoff mappings by code.
    protocol CappedHandoffMappingStore {
        func find(_ code: String) -> CappedHandoffMapping?
        func save(_ item: CappedHandoffMapping)
        func remove(_ code: String) -> Bool
        func list() -> [CappedHandoffMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedHandoffMappingStore: CappedHandoffMappingStore {
        var items: [String: CappedHandoffMapping]
        var order: [String]

        init(items: [String: CappedHandoffMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedHandoffMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedHandoffMapping) {
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

        func list() -> [CappedHandoffMapping] {
            var out: [CappedHandoffMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedHandoffMappingStore() -> any CappedHandoffMappingStore {
        return MemoryCappedHandoffMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedHandoffMappingStore: CappedHandoffMappingStore {
        var inner: MemoryCappedHandoffMappingStore
        var cache: TTLCache<CappedHandoffMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedHandoffMappingStore, cache: TTLCache<CappedHandoffMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedHandoffMapping? {
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

        func save(_ item: CappedHandoffMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedHandoffMapping] {
            return inner.list()
        }
    }

    static func newCachedCappedHandoffMappingStore(_ inner: MemoryCappedHandoffMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedHandoffMappingStore {
        return CachedCappedHandoffMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped handoff mappings. Empty fields match all.
    final class CappedHandoffMappingQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedHandoffMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CappedHandoffMapping]) -> [CappedHandoffMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedHandoffMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedHandoffMappings(_ store: any CappedHandoffMappingStore, query: CappedHandoffMappingQuery) -> [CappedHandoffMapping] {
        return query.apply(store.list())
    }
}

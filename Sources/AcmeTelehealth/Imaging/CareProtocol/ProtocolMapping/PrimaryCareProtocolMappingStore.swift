import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary care protocol mappings by code.
    protocol PrimaryCareProtocolMappingStore {
        func find(_ code: String) -> PrimaryCareProtocolMapping?
        func save(_ item: PrimaryCareProtocolMapping)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryCareProtocolMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryCareProtocolMappingStore: PrimaryCareProtocolMappingStore {
        var items: [String: PrimaryCareProtocolMapping]
        var order: [String]

        init(items: [String: PrimaryCareProtocolMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryCareProtocolMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryCareProtocolMapping) {
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

        func list() -> [PrimaryCareProtocolMapping] {
            var out: [PrimaryCareProtocolMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryCareProtocolMappingStore() -> any PrimaryCareProtocolMappingStore {
        return MemoryPrimaryCareProtocolMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryCareProtocolMappingStore: PrimaryCareProtocolMappingStore {
        var inner: MemoryPrimaryCareProtocolMappingStore
        var cache: TTLCache<PrimaryCareProtocolMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryCareProtocolMappingStore, cache: TTLCache<PrimaryCareProtocolMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryCareProtocolMapping? {
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

        func save(_ item: PrimaryCareProtocolMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryCareProtocolMapping] {
            return inner.list()
        }
    }

    static func newCachedPrimaryCareProtocolMappingStore(_ inner: MemoryPrimaryCareProtocolMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryCareProtocolMappingStore {
        return CachedPrimaryCareProtocolMappingStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary care protocol mappings. Empty fields match all.
    final class PrimaryCareProtocolMappingQuery {
        var locale: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryCareProtocolMapping) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryCareProtocolMapping]) -> [PrimaryCareProtocolMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryCareProtocolMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryCareProtocolMappings(_ store: any PrimaryCareProtocolMappingStore, query: PrimaryCareProtocolMappingQuery) -> [PrimaryCareProtocolMapping] {
        return query.apply(store.list())
    }
}

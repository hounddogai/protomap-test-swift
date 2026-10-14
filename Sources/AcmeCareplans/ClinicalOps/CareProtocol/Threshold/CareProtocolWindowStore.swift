import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol windows by code.
    protocol CareProtocolWindowStore {
        func find(_ code: String) -> CareProtocolWindow?
        func save(_ item: CareProtocolWindow)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolWindowStore: CareProtocolWindowStore {
        var items: [String: CareProtocolWindow]
        var order: [String]

        init(items: [String: CareProtocolWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolWindow) {
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

        func list() -> [CareProtocolWindow] {
            var out: [CareProtocolWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolWindowStore() -> any CareProtocolWindowStore {
        return MemoryCareProtocolWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolWindowStore: CareProtocolWindowStore {
        var inner: MemoryCareProtocolWindowStore
        var cache: TTLCache<CareProtocolWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolWindowStore, cache: TTLCache<CareProtocolWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolWindow? {
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

        func save(_ item: CareProtocolWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolWindow] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolWindowStore(_ inner: MemoryCareProtocolWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolWindowStore {
        return CachedCareProtocolWindowStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol windows. Empty fields match all.
    final class CareProtocolWindowQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolWindow]) -> [CareProtocolWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolWindows(_ store: any CareProtocolWindowStore, query: CareProtocolWindowQuery) -> [CareProtocolWindow] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach mappings by code.
    protocol OutreachMappingStore {
        func find(_ code: String) -> OutreachMapping?
        func save(_ item: OutreachMapping)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachMappingStore: OutreachMappingStore {
        var items: [String: OutreachMapping]
        var order: [String]

        init(items: [String: OutreachMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachMapping) {
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

        func list() -> [OutreachMapping] {
            var out: [OutreachMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachMappingStore() -> any OutreachMappingStore {
        return MemoryOutreachMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachMappingStore: OutreachMappingStore {
        var inner: MemoryOutreachMappingStore
        var cache: TTLCache<OutreachMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachMappingStore, cache: TTLCache<OutreachMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachMapping? {
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

        func save(_ item: OutreachMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachMapping] {
            return inner.list()
        }
    }

    static func newCachedOutreachMappingStore(_ inner: MemoryOutreachMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachMappingStore {
        return CachedOutreachMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach mappings. Empty fields match all.
    final class OutreachMappingQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachMapping) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachMapping]) -> [OutreachMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachMappings(_ store: any OutreachMappingStore, query: OutreachMappingQuery) -> [OutreachMapping] {
        return query.apply(store.list())
    }
}

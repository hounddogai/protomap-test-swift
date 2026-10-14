import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending remittance mappings by code.
    protocol PendingRemittanceMappingStore {
        func find(_ code: String) -> PendingRemittanceMapping?
        func save(_ item: PendingRemittanceMapping)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRemittanceMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRemittanceMappingStore: PendingRemittanceMappingStore {
        var items: [String: PendingRemittanceMapping]
        var order: [String]

        init(items: [String: PendingRemittanceMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRemittanceMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRemittanceMapping) {
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

        func list() -> [PendingRemittanceMapping] {
            var out: [PendingRemittanceMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRemittanceMappingStore() -> any PendingRemittanceMappingStore {
        return MemoryPendingRemittanceMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRemittanceMappingStore: PendingRemittanceMappingStore {
        var inner: MemoryPendingRemittanceMappingStore
        var cache: TTLCache<PendingRemittanceMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRemittanceMappingStore, cache: TTLCache<PendingRemittanceMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRemittanceMapping? {
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

        func save(_ item: PendingRemittanceMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRemittanceMapping] {
            return inner.list()
        }
    }

    static func newCachedPendingRemittanceMappingStore(_ inner: MemoryPendingRemittanceMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRemittanceMappingStore {
        return CachedPendingRemittanceMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending remittance mappings. Empty fields match all.
    final class PendingRemittanceMappingQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRemittanceMapping) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRemittanceMapping]) -> [PendingRemittanceMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRemittanceMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRemittanceMappings(_ store: any PendingRemittanceMappingStore, query: PendingRemittanceMappingQuery) -> [PendingRemittanceMapping] {
        return query.apply(store.list())
    }
}

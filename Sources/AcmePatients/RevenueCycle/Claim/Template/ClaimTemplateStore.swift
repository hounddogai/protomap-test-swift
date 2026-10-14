import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim templates by code.
    protocol ClaimTemplateStore {
        func find(_ code: String) -> ClaimTemplate?
        func save(_ item: ClaimTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimTemplateStore: ClaimTemplateStore {
        var items: [String: ClaimTemplate]
        var order: [String]

        init(items: [String: ClaimTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimTemplate) {
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

        func list() -> [ClaimTemplate] {
            var out: [ClaimTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimTemplateStore() -> any ClaimTemplateStore {
        return MemoryClaimTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimTemplateStore: ClaimTemplateStore {
        var inner: MemoryClaimTemplateStore
        var cache: TTLCache<ClaimTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimTemplateStore, cache: TTLCache<ClaimTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimTemplate? {
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

        func save(_ item: ClaimTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimTemplate] {
            return inner.list()
        }
    }

    static func newCachedClaimTemplateStore(_ inner: MemoryClaimTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimTemplateStore {
        return CachedClaimTemplateStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim templates. Empty fields match all.
    final class ClaimTemplateQuery {
        var ward: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimTemplate) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimTemplate]) -> [ClaimTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimTemplates(_ store: any ClaimTemplateStore, query: ClaimTemplateQuery) -> [ClaimTemplate] {
        return query.apply(store.list())
    }
}

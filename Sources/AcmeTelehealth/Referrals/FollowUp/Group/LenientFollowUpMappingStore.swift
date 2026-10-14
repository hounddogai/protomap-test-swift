import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps lenient follow up mappings by code.
    protocol LenientFollowUpMappingStore {
        func find(_ code: String) -> LenientFollowUpMapping?
        func save(_ item: LenientFollowUpMapping)
        func remove(_ code: String) -> Bool
        func list() -> [LenientFollowUpMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientFollowUpMappingStore: LenientFollowUpMappingStore {
        var items: [String: LenientFollowUpMapping]
        var order: [String]

        init(items: [String: LenientFollowUpMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientFollowUpMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientFollowUpMapping) {
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

        func list() -> [LenientFollowUpMapping] {
            var out: [LenientFollowUpMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientFollowUpMappingStore() -> any LenientFollowUpMappingStore {
        return MemoryLenientFollowUpMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientFollowUpMappingStore: LenientFollowUpMappingStore {
        var inner: MemoryLenientFollowUpMappingStore
        var cache: TTLCache<LenientFollowUpMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientFollowUpMappingStore, cache: TTLCache<LenientFollowUpMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientFollowUpMapping? {
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

        func save(_ item: LenientFollowUpMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientFollowUpMapping] {
            return inner.list()
        }
    }

    static func newCachedLenientFollowUpMappingStore(_ inner: MemoryLenientFollowUpMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientFollowUpMappingStore {
        return CachedLenientFollowUpMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient follow up mappings. Empty fields match all.
    final class LenientFollowUpMappingQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientFollowUpMapping) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientFollowUpMapping]) -> [LenientFollowUpMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientFollowUpMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientFollowUpMappings(_ store: any LenientFollowUpMappingStore, query: LenientFollowUpMappingQuery) -> [LenientFollowUpMapping] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language adjustments by code.
    protocol LanguageAdjustmentStore {
        func find(_ code: String) -> LanguageAdjustment?
        func save(_ item: LanguageAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageAdjustmentStore: LanguageAdjustmentStore {
        var items: [String: LanguageAdjustment]
        var order: [String]

        init(items: [String: LanguageAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageAdjustment) {
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

        func list() -> [LanguageAdjustment] {
            var out: [LanguageAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageAdjustmentStore() -> any LanguageAdjustmentStore {
        return MemoryLanguageAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageAdjustmentStore: LanguageAdjustmentStore {
        var inner: MemoryLanguageAdjustmentStore
        var cache: TTLCache<LanguageAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageAdjustmentStore, cache: TTLCache<LanguageAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageAdjustment? {
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

        func save(_ item: LanguageAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageAdjustment] {
            return inner.list()
        }
    }

    static func newCachedLanguageAdjustmentStore(_ inner: MemoryLanguageAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageAdjustmentStore {
        return CachedLanguageAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language adjustments. Empty fields match all.
    final class LanguageAdjustmentQuery {
        var segment: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageAdjustment) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageAdjustment]) -> [LanguageAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageAdjustments(_ store: any LanguageAdjustmentStore, query: LanguageAdjustmentQuery) -> [LanguageAdjustment] {
        return query.apply(store.list())
    }
}

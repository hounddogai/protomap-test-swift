import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual program overrides by code.
    protocol ManualProgramOverrideStore {
        func find(_ code: String) -> ManualProgramOverride?
        func save(_ item: ManualProgramOverride)
        func remove(_ code: String) -> Bool
        func list() -> [ManualProgramOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualProgramOverrideStore: ManualProgramOverrideStore {
        var items: [String: ManualProgramOverride]
        var order: [String]

        init(items: [String: ManualProgramOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualProgramOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualProgramOverride) {
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

        func list() -> [ManualProgramOverride] {
            var out: [ManualProgramOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualProgramOverrideStore() -> any ManualProgramOverrideStore {
        return MemoryManualProgramOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualProgramOverrideStore: ManualProgramOverrideStore {
        var inner: MemoryManualProgramOverrideStore
        var cache: TTLCache<ManualProgramOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualProgramOverrideStore, cache: TTLCache<ManualProgramOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualProgramOverride? {
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

        func save(_ item: ManualProgramOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualProgramOverride] {
            return inner.list()
        }
    }

    static func newCachedManualProgramOverrideStore(_ inner: MemoryManualProgramOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualProgramOverrideStore {
        return CachedManualProgramOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual program overrides. Empty fields match all.
    final class ManualProgramOverrideQuery {
        var locale: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualProgramOverride) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualProgramOverride]) -> [ManualProgramOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualProgramOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualProgramOverrides(_ store: any ManualProgramOverrideStore, query: ManualProgramOverrideQuery) -> [ManualProgramOverride] {
        return query.apply(store.list())
    }
}

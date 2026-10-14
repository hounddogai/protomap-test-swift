import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession overrides by code.
    protocol AccessionOverrideStore {
        func find(_ code: String) -> AccessionOverride?
        func save(_ item: AccessionOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionOverrideStore: AccessionOverrideStore {
        var items: [String: AccessionOverride]
        var order: [String]

        init(items: [String: AccessionOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionOverride) {
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

        func list() -> [AccessionOverride] {
            var out: [AccessionOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionOverrideStore() -> any AccessionOverrideStore {
        return MemoryAccessionOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionOverrideStore: AccessionOverrideStore {
        var inner: MemoryAccessionOverrideStore
        var cache: TTLCache<AccessionOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionOverrideStore, cache: TTLCache<AccessionOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionOverride? {
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

        func save(_ item: AccessionOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionOverride] {
            return inner.list()
        }
    }

    static func newCachedAccessionOverrideStore(_ inner: MemoryAccessionOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionOverrideStore {
        return CachedAccessionOverrideStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession overrides. Empty fields match all.
    final class AccessionOverrideQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionOverride]) -> [AccessionOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionOverrides(_ store: any AccessionOverrideStore, query: AccessionOverrideQuery) -> [AccessionOverride] {
        return query.apply(store.list())
    }
}

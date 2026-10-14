import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure baselines by code.
    protocol DisclosureBaselineStore {
        func find(_ code: String) -> DisclosureBaseline?
        func save(_ item: DisclosureBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureBaselineStore: DisclosureBaselineStore {
        var items: [String: DisclosureBaseline]
        var order: [String]

        init(items: [String: DisclosureBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureBaseline) {
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

        func list() -> [DisclosureBaseline] {
            var out: [DisclosureBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureBaselineStore() -> any DisclosureBaselineStore {
        return MemoryDisclosureBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureBaselineStore: DisclosureBaselineStore {
        var inner: MemoryDisclosureBaselineStore
        var cache: TTLCache<DisclosureBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureBaselineStore, cache: TTLCache<DisclosureBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureBaseline? {
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

        func save(_ item: DisclosureBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureBaseline] {
            return inner.list()
        }
    }

    static func newCachedDisclosureBaselineStore(_ inner: MemoryDisclosureBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureBaselineStore {
        return CachedDisclosureBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure baselines. Empty fields match all.
    final class DisclosureBaselineQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureBaseline]) -> [DisclosureBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureBaselines(_ store: any DisclosureBaselineStore, query: DisclosureBaselineQuery) -> [DisclosureBaseline] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime drafts by code.
    protocol OvertimeDraftStore {
        func find(_ code: String) -> OvertimeDraft?
        func save(_ item: OvertimeDraft)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeDraftStore: OvertimeDraftStore {
        var items: [String: OvertimeDraft]
        var order: [String]

        init(items: [String: OvertimeDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeDraft) {
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

        func list() -> [OvertimeDraft] {
            var out: [OvertimeDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeDraftStore() -> any OvertimeDraftStore {
        return MemoryOvertimeDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeDraftStore: OvertimeDraftStore {
        var inner: MemoryOvertimeDraftStore
        var cache: TTLCache<OvertimeDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeDraftStore, cache: TTLCache<OvertimeDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeDraft? {
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

        func save(_ item: OvertimeDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeDraft] {
            return inner.list()
        }
    }

    static func newCachedOvertimeDraftStore(_ inner: MemoryOvertimeDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeDraftStore {
        return CachedOvertimeDraftStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime drafts. Empty fields match all.
    final class OvertimeDraftQuery {
        var label: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCost: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [OvertimeDraft]) -> [OvertimeDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeDrafts(_ store: any OvertimeDraftStore, query: OvertimeDraftQuery) -> [OvertimeDraft] {
        return query.apply(store.list())
    }
}

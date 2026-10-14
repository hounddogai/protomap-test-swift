import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling overtime drafts by code.
    protocol RollingOvertimeDraftStore {
        func find(_ code: String) -> RollingOvertimeDraft?
        func save(_ item: RollingOvertimeDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RollingOvertimeDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingOvertimeDraftStore: RollingOvertimeDraftStore {
        var items: [String: RollingOvertimeDraft]
        var order: [String]

        init(items: [String: RollingOvertimeDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingOvertimeDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingOvertimeDraft) {
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

        func list() -> [RollingOvertimeDraft] {
            var out: [RollingOvertimeDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingOvertimeDraftStore() -> any RollingOvertimeDraftStore {
        return MemoryRollingOvertimeDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingOvertimeDraftStore: RollingOvertimeDraftStore {
        var inner: MemoryRollingOvertimeDraftStore
        var cache: TTLCache<RollingOvertimeDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingOvertimeDraftStore, cache: TTLCache<RollingOvertimeDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingOvertimeDraft? {
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

        func save(_ item: RollingOvertimeDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingOvertimeDraft] {
            return inner.list()
        }
    }

    static func newCachedRollingOvertimeDraftStore(_ inner: MemoryRollingOvertimeDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingOvertimeDraftStore {
        return CachedRollingOvertimeDraftStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling overtime drafts. Empty fields match all.
    final class RollingOvertimeDraftQuery {
        var country: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingOvertimeDraft) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingOvertimeDraft]) -> [RollingOvertimeDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingOvertimeDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingOvertimeDrafts(_ store: any RollingOvertimeDraftStore, query: RollingOvertimeDraftQuery) -> [RollingOvertimeDraft] {
        return query.apply(store.list())
    }
}

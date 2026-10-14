import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist profiles by code.
    protocol WorklistProfileStore {
        func find(_ code: String) -> WorklistProfile?
        func save(_ item: WorklistProfile)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistProfileStore: WorklistProfileStore {
        var items: [String: WorklistProfile]
        var order: [String]

        init(items: [String: WorklistProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistProfile) {
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

        func list() -> [WorklistProfile] {
            var out: [WorklistProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistProfileStore() -> any WorklistProfileStore {
        return MemoryWorklistProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistProfileStore: WorklistProfileStore {
        var inner: MemoryWorklistProfileStore
        var cache: TTLCache<WorklistProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistProfileStore, cache: TTLCache<WorklistProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistProfile? {
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

        func save(_ item: WorklistProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistProfile] {
            return inner.list()
        }
    }

    static func newCachedWorklistProfileStore(_ inner: MemoryWorklistProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistProfileStore {
        return CachedWorklistProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist profiles. Empty fields match all.
    final class WorklistProfileQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistProfile) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistProfile]) -> [WorklistProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistProfiles(_ store: any WorklistProfileStore, query: WorklistProfileQuery) -> [WorklistProfile] {
        return query.apply(store.list())
    }
}

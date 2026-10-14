import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient worklist profiles by code.
    protocol LenientWorklistProfileStore {
        func find(_ code: String) -> LenientWorklistProfile?
        func save(_ item: LenientWorklistProfile)
        func remove(_ code: String) -> Bool
        func list() -> [LenientWorklistProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientWorklistProfileStore: LenientWorklistProfileStore {
        var items: [String: LenientWorklistProfile]
        var order: [String]

        init(items: [String: LenientWorklistProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientWorklistProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientWorklistProfile) {
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

        func list() -> [LenientWorklistProfile] {
            var out: [LenientWorklistProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientWorklistProfileStore() -> any LenientWorklistProfileStore {
        return MemoryLenientWorklistProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientWorklistProfileStore: LenientWorklistProfileStore {
        var inner: MemoryLenientWorklistProfileStore
        var cache: TTLCache<LenientWorklistProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientWorklistProfileStore, cache: TTLCache<LenientWorklistProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientWorklistProfile? {
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

        func save(_ item: LenientWorklistProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientWorklistProfile] {
            return inner.list()
        }
    }

    static func newCachedLenientWorklistProfileStore(_ inner: MemoryLenientWorklistProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientWorklistProfileStore {
        return CachedLenientWorklistProfileStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient worklist profiles. Empty fields match all.
    final class LenientWorklistProfileQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientWorklistProfile) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [LenientWorklistProfile]) -> [LenientWorklistProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientWorklistProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientWorklistProfiles(_ store: any LenientWorklistProfileStore, query: LenientWorklistProfileQuery) -> [LenientWorklistProfile] {
        return query.apply(store.list())
    }
}

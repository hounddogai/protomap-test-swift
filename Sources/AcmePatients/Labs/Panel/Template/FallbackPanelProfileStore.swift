import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback panel profiles by code.
    protocol FallbackPanelProfileStore {
        func find(_ code: String) -> FallbackPanelProfile?
        func save(_ item: FallbackPanelProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackPanelProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackPanelProfileStore: FallbackPanelProfileStore {
        var items: [String: FallbackPanelProfile]
        var order: [String]

        init(items: [String: FallbackPanelProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackPanelProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackPanelProfile) {
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

        func list() -> [FallbackPanelProfile] {
            var out: [FallbackPanelProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackPanelProfileStore() -> any FallbackPanelProfileStore {
        return MemoryFallbackPanelProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackPanelProfileStore: FallbackPanelProfileStore {
        var inner: MemoryFallbackPanelProfileStore
        var cache: TTLCache<FallbackPanelProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackPanelProfileStore, cache: TTLCache<FallbackPanelProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackPanelProfile? {
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

        func save(_ item: FallbackPanelProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackPanelProfile] {
            return inner.list()
        }
    }

    static func newCachedFallbackPanelProfileStore(_ inner: MemoryFallbackPanelProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackPanelProfileStore {
        return CachedFallbackPanelProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback panel profiles. Empty fields match all.
    final class FallbackPanelProfileQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackPanelProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackPanelProfile]) -> [FallbackPanelProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackPanelProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackPanelProfiles(_ store: any FallbackPanelProfileStore, query: FallbackPanelProfileQuery) -> [FallbackPanelProfile] {
        return query.apply(store.list())
    }
}

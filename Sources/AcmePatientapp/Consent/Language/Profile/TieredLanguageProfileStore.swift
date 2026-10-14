import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered language profiles by code.
    protocol TieredLanguageProfileStore {
        func find(_ code: String) -> TieredLanguageProfile?
        func save(_ item: TieredLanguageProfile)
        func remove(_ code: String) -> Bool
        func list() -> [TieredLanguageProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredLanguageProfileStore: TieredLanguageProfileStore {
        var items: [String: TieredLanguageProfile]
        var order: [String]

        init(items: [String: TieredLanguageProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredLanguageProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredLanguageProfile) {
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

        func list() -> [TieredLanguageProfile] {
            var out: [TieredLanguageProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredLanguageProfileStore() -> any TieredLanguageProfileStore {
        return MemoryTieredLanguageProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredLanguageProfileStore: TieredLanguageProfileStore {
        var inner: MemoryTieredLanguageProfileStore
        var cache: TTLCache<TieredLanguageProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredLanguageProfileStore, cache: TTLCache<TieredLanguageProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredLanguageProfile? {
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

        func save(_ item: TieredLanguageProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredLanguageProfile] {
            return inner.list()
        }
    }

    static func newCachedTieredLanguageProfileStore(_ inner: MemoryTieredLanguageProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredLanguageProfileStore {
        return CachedTieredLanguageProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered language profiles. Empty fields match all.
    final class TieredLanguageProfileQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredLanguageProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredLanguageProfile]) -> [TieredLanguageProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredLanguageProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredLanguageProfiles(_ store: any TieredLanguageProfileStore, query: TieredLanguageProfileQuery) -> [TieredLanguageProfile] {
        return query.apply(store.list())
    }
}

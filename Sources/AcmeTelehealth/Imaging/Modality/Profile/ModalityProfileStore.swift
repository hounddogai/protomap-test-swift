import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality profiles by code.
    protocol ModalityProfileStore {
        func find(_ code: String) -> ModalityProfile?
        func save(_ item: ModalityProfile)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityProfileStore: ModalityProfileStore {
        var items: [String: ModalityProfile]
        var order: [String]

        init(items: [String: ModalityProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityProfile) {
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

        func list() -> [ModalityProfile] {
            var out: [ModalityProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityProfileStore() -> any ModalityProfileStore {
        return MemoryModalityProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityProfileStore: ModalityProfileStore {
        var inner: MemoryModalityProfileStore
        var cache: TTLCache<ModalityProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityProfileStore, cache: TTLCache<ModalityProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityProfile? {
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

        func save(_ item: ModalityProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityProfile] {
            return inner.list()
        }
    }

    static func newCachedModalityProfileStore(_ inner: MemoryModalityProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityProfileStore {
        return CachedModalityProfileStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality profiles. Empty fields match all.
    final class ModalityProfileQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityProfile]) -> [ModalityProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityProfiles(_ store: any ModalityProfileStore, query: ModalityProfileQuery) -> [ModalityProfile] {
        return query.apply(store.list())
    }
}

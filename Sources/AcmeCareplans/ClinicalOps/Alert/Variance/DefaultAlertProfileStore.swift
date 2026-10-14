import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps default alert profiles by code.
    protocol DefaultAlertProfileStore {
        func find(_ code: String) -> DefaultAlertProfile?
        func save(_ item: DefaultAlertProfile)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAlertProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAlertProfileStore: DefaultAlertProfileStore {
        var items: [String: DefaultAlertProfile]
        var order: [String]

        init(items: [String: DefaultAlertProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAlertProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAlertProfile) {
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

        func list() -> [DefaultAlertProfile] {
            var out: [DefaultAlertProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAlertProfileStore() -> any DefaultAlertProfileStore {
        return MemoryDefaultAlertProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAlertProfileStore: DefaultAlertProfileStore {
        var inner: MemoryDefaultAlertProfileStore
        var cache: TTLCache<DefaultAlertProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAlertProfileStore, cache: TTLCache<DefaultAlertProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAlertProfile? {
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

        func save(_ item: DefaultAlertProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAlertProfile] {
            return inner.list()
        }
    }

    static func newCachedDefaultAlertProfileStore(_ inner: MemoryDefaultAlertProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAlertProfileStore {
        return CachedDefaultAlertProfileStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default alert profiles. Empty fields match all.
    final class DefaultAlertProfileQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAlertProfile) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAlertProfile]) -> [DefaultAlertProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAlertProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAlertProfiles(_ store: any DefaultAlertProfileStore, query: DefaultAlertProfileQuery) -> [DefaultAlertProfile] {
        return query.apply(store.list())
    }
}

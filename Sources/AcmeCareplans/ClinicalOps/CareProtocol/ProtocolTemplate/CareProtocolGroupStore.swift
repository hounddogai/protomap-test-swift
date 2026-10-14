import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol groups by code.
    protocol CareProtocolGroupStore {
        func find(_ code: String) -> CareProtocolGroup?
        func save(_ item: CareProtocolGroup)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolGroupStore: CareProtocolGroupStore {
        var items: [String: CareProtocolGroup]
        var order: [String]

        init(items: [String: CareProtocolGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolGroup) {
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

        func list() -> [CareProtocolGroup] {
            var out: [CareProtocolGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolGroupStore() -> any CareProtocolGroupStore {
        return MemoryCareProtocolGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolGroupStore: CareProtocolGroupStore {
        var inner: MemoryCareProtocolGroupStore
        var cache: TTLCache<CareProtocolGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolGroupStore, cache: TTLCache<CareProtocolGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolGroup? {
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

        func save(_ item: CareProtocolGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolGroup] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolGroupStore(_ inner: MemoryCareProtocolGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolGroupStore {
        return CachedCareProtocolGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol groups. Empty fields match all.
    final class CareProtocolGroupQuery {
        var locale: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolGroup) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolGroup]) -> [CareProtocolGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolGroups(_ store: any CareProtocolGroupStore, query: CareProtocolGroupQuery) -> [CareProtocolGroup] {
        return query.apply(store.list())
    }
}

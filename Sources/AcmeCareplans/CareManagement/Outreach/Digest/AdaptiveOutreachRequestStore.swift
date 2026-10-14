import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive outreach requests by code.
    protocol AdaptiveOutreachRequestStore {
        func find(_ code: String) -> AdaptiveOutreachRequest?
        func save(_ item: AdaptiveOutreachRequest)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveOutreachRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveOutreachRequestStore: AdaptiveOutreachRequestStore {
        var items: [String: AdaptiveOutreachRequest]
        var order: [String]

        init(items: [String: AdaptiveOutreachRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveOutreachRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveOutreachRequest) {
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

        func list() -> [AdaptiveOutreachRequest] {
            var out: [AdaptiveOutreachRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveOutreachRequestStore() -> any AdaptiveOutreachRequestStore {
        return MemoryAdaptiveOutreachRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveOutreachRequestStore: AdaptiveOutreachRequestStore {
        var inner: MemoryAdaptiveOutreachRequestStore
        var cache: TTLCache<AdaptiveOutreachRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveOutreachRequestStore, cache: TTLCache<AdaptiveOutreachRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveOutreachRequest? {
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

        func save(_ item: AdaptiveOutreachRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveOutreachRequest] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveOutreachRequestStore(_ inner: MemoryAdaptiveOutreachRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveOutreachRequestStore {
        return CachedAdaptiveOutreachRequestStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive outreach requests. Empty fields match all.
    final class AdaptiveOutreachRequestQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveOutreachRequest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveOutreachRequest]) -> [AdaptiveOutreachRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveOutreachRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveOutreachRequests(_ store: any AdaptiveOutreachRequestStore, query: AdaptiveOutreachRequestQuery) -> [AdaptiveOutreachRequest] {
        return query.apply(store.list())
    }
}

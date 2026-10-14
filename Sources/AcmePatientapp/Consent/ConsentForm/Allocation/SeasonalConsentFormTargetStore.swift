import AcmePlatform
import Foundation

extension Consent {
    /// Keeps seasonal consent form targets by code.
    protocol SeasonalConsentFormTargetStore {
        func find(_ code: String) -> SeasonalConsentFormTarget?
        func save(_ item: SeasonalConsentFormTarget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalConsentFormTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalConsentFormTargetStore: SeasonalConsentFormTargetStore {
        var items: [String: SeasonalConsentFormTarget]
        var order: [String]

        init(items: [String: SeasonalConsentFormTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalConsentFormTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalConsentFormTarget) {
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

        func list() -> [SeasonalConsentFormTarget] {
            var out: [SeasonalConsentFormTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalConsentFormTargetStore() -> any SeasonalConsentFormTargetStore {
        return MemorySeasonalConsentFormTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalConsentFormTargetStore: SeasonalConsentFormTargetStore {
        var inner: MemorySeasonalConsentFormTargetStore
        var cache: TTLCache<SeasonalConsentFormTarget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalConsentFormTargetStore, cache: TTLCache<SeasonalConsentFormTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalConsentFormTarget? {
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

        func save(_ item: SeasonalConsentFormTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalConsentFormTarget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalConsentFormTargetStore(_ inner: MemorySeasonalConsentFormTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalConsentFormTargetStore {
        return CachedSeasonalConsentFormTargetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal consent form targets. Empty fields match all.
    final class SeasonalConsentFormTargetQuery {
        var channel: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalConsentFormTarget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalConsentFormTarget]) -> [SeasonalConsentFormTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalConsentFormTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalConsentFormTargets(_ store: any SeasonalConsentFormTargetStore, query: SeasonalConsentFormTargetQuery) -> [SeasonalConsentFormTarget] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language plans by code.
    protocol LanguagePlanStore {
        func find(_ code: String) -> LanguagePlan?
        func save(_ item: LanguagePlan)
        func remove(_ code: String) -> Bool
        func list() -> [LanguagePlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguagePlanStore: LanguagePlanStore {
        var items: [String: LanguagePlan]
        var order: [String]

        init(items: [String: LanguagePlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguagePlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguagePlan) {
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

        func list() -> [LanguagePlan] {
            var out: [LanguagePlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguagePlanStore() -> any LanguagePlanStore {
        return MemoryLanguagePlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguagePlanStore: LanguagePlanStore {
        var inner: MemoryLanguagePlanStore
        var cache: TTLCache<LanguagePlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguagePlanStore, cache: TTLCache<LanguagePlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguagePlan? {
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

        func save(_ item: LanguagePlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguagePlan] {
            return inner.list()
        }
    }

    static func newCachedLanguagePlanStore(_ inner: MemoryLanguagePlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguagePlanStore {
        return CachedLanguagePlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language plans. Empty fields match all.
    final class LanguagePlanQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguagePlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguagePlan]) -> [LanguagePlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguagePlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguagePlans(_ store: any LanguagePlanStore, query: LanguagePlanQuery) -> [LanguagePlan] {
        return query.apply(store.list())
    }
}

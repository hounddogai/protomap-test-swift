import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps fallback skill mix templates by code.
    protocol FallbackSkillMixTemplateStore {
        func find(_ code: String) -> FallbackSkillMixTemplate?
        func save(_ item: FallbackSkillMixTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSkillMixTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSkillMixTemplateStore: FallbackSkillMixTemplateStore {
        var items: [String: FallbackSkillMixTemplate]
        var order: [String]

        init(items: [String: FallbackSkillMixTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSkillMixTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSkillMixTemplate) {
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

        func list() -> [FallbackSkillMixTemplate] {
            var out: [FallbackSkillMixTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSkillMixTemplateStore() -> any FallbackSkillMixTemplateStore {
        return MemoryFallbackSkillMixTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSkillMixTemplateStore: FallbackSkillMixTemplateStore {
        var inner: MemoryFallbackSkillMixTemplateStore
        var cache: TTLCache<FallbackSkillMixTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSkillMixTemplateStore, cache: TTLCache<FallbackSkillMixTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSkillMixTemplate? {
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

        func save(_ item: FallbackSkillMixTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSkillMixTemplate] {
            return inner.list()
        }
    }

    static func newCachedFallbackSkillMixTemplateStore(_ inner: MemoryFallbackSkillMixTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSkillMixTemplateStore {
        return CachedFallbackSkillMixTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback skill mix templates. Empty fields match all.
    final class FallbackSkillMixTemplateQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSkillMixTemplate) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackSkillMixTemplate]) -> [FallbackSkillMixTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSkillMixTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSkillMixTemplates(_ store: any FallbackSkillMixTemplateStore, query: FallbackSkillMixTemplateQuery) -> [FallbackSkillMixTemplate] {
        return query.apply(store.list())
    }
}

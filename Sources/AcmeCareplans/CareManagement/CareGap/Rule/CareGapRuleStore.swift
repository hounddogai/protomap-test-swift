import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap rules by code.
    protocol CareGapRuleStore {
        func find(_ code: String) -> CareGapRule?
        func save(_ item: CareGapRule)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapRuleStore: CareGapRuleStore {
        var items: [String: CareGapRule]
        var order: [String]

        init(items: [String: CareGapRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapRule) {
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

        func list() -> [CareGapRule] {
            var out: [CareGapRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapRuleStore() -> any CareGapRuleStore {
        return MemoryCareGapRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapRuleStore: CareGapRuleStore {
        var inner: MemoryCareGapRuleStore
        var cache: TTLCache<CareGapRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapRuleStore, cache: TTLCache<CareGapRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapRule? {
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

        func save(_ item: CareGapRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapRule] {
            return inner.list()
        }
    }

    static func newCachedCareGapRuleStore(_ inner: MemoryCareGapRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapRuleStore {
        return CachedCareGapRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap rules. Empty fields match all.
    final class CareGapRuleQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapRule]) -> [CareGapRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapRules(_ store: any CareGapRuleStore, query: CareGapRuleQuery) -> [CareGapRule] {
        return query.apply(store.list())
    }
}

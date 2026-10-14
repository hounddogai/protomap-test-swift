import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global specimen rules by code.
    protocol GlobalSpecimenRuleStore {
        func find(_ code: String) -> GlobalSpecimenRule?
        func save(_ item: GlobalSpecimenRule)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSpecimenRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSpecimenRuleStore: GlobalSpecimenRuleStore {
        var items: [String: GlobalSpecimenRule]
        var order: [String]

        init(items: [String: GlobalSpecimenRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSpecimenRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSpecimenRule) {
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

        func list() -> [GlobalSpecimenRule] {
            var out: [GlobalSpecimenRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSpecimenRuleStore() -> any GlobalSpecimenRuleStore {
        return MemoryGlobalSpecimenRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSpecimenRuleStore: GlobalSpecimenRuleStore {
        var inner: MemoryGlobalSpecimenRuleStore
        var cache: TTLCache<GlobalSpecimenRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSpecimenRuleStore, cache: TTLCache<GlobalSpecimenRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSpecimenRule? {
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

        func save(_ item: GlobalSpecimenRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSpecimenRule] {
            return inner.list()
        }
    }

    static func newCachedGlobalSpecimenRuleStore(_ inner: MemoryGlobalSpecimenRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSpecimenRuleStore {
        return CachedGlobalSpecimenRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global specimen rules. Empty fields match all.
    final class GlobalSpecimenRuleQuery {
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

        func matches(_ item: GlobalSpecimenRule) -> Bool {
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

        func apply(_ items: [GlobalSpecimenRule]) -> [GlobalSpecimenRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSpecimenRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSpecimenRules(_ store: any GlobalSpecimenRuleStore, query: GlobalSpecimenRuleQuery) -> [GlobalSpecimenRule] {
        return query.apply(store.list())
    }
}

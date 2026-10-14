import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps regional study rules by code.
    protocol RegionalStudyRuleStore {
        func find(_ code: String) -> RegionalStudyRule?
        func save(_ item: RegionalStudyRule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStudyRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStudyRuleStore: RegionalStudyRuleStore {
        var items: [String: RegionalStudyRule]
        var order: [String]

        init(items: [String: RegionalStudyRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStudyRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStudyRule) {
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

        func list() -> [RegionalStudyRule] {
            var out: [RegionalStudyRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStudyRuleStore() -> any RegionalStudyRuleStore {
        return MemoryRegionalStudyRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStudyRuleStore: RegionalStudyRuleStore {
        var inner: MemoryRegionalStudyRuleStore
        var cache: TTLCache<RegionalStudyRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStudyRuleStore, cache: TTLCache<RegionalStudyRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStudyRule? {
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

        func save(_ item: RegionalStudyRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStudyRule] {
            return inner.list()
        }
    }

    static func newCachedRegionalStudyRuleStore(_ inner: MemoryRegionalStudyRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStudyRuleStore {
        return CachedRegionalStudyRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional study rules. Empty fields match all.
    final class RegionalStudyRuleQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStudyRule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalStudyRule]) -> [RegionalStudyRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStudyRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStudyRules(_ store: any RegionalStudyRuleStore, query: RegionalStudyRuleQuery) -> [RegionalStudyRule] {
        return query.apply(store.list())
    }
}

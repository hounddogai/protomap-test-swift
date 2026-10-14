import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled language rules by code.
    protocol ScheduledLanguageRuleStore {
        func find(_ code: String) -> ScheduledLanguageRule?
        func save(_ item: ScheduledLanguageRule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledLanguageRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledLanguageRuleStore: ScheduledLanguageRuleStore {
        var items: [String: ScheduledLanguageRule]
        var order: [String]

        init(items: [String: ScheduledLanguageRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledLanguageRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledLanguageRule) {
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

        func list() -> [ScheduledLanguageRule] {
            var out: [ScheduledLanguageRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledLanguageRuleStore() -> any ScheduledLanguageRuleStore {
        return MemoryScheduledLanguageRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledLanguageRuleStore: ScheduledLanguageRuleStore {
        var inner: MemoryScheduledLanguageRuleStore
        var cache: TTLCache<ScheduledLanguageRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledLanguageRuleStore, cache: TTLCache<ScheduledLanguageRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledLanguageRule? {
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

        func save(_ item: ScheduledLanguageRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledLanguageRule] {
            return inner.list()
        }
    }

    static func newCachedScheduledLanguageRuleStore(_ inner: MemoryScheduledLanguageRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledLanguageRuleStore {
        return CachedScheduledLanguageRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled language rules. Empty fields match all.
    final class ScheduledLanguageRuleQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledLanguageRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledLanguageRule]) -> [ScheduledLanguageRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledLanguageRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledLanguageRules(_ store: any ScheduledLanguageRuleStore, query: ScheduledLanguageRuleQuery) -> [ScheduledLanguageRule] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient study rules by code.
    protocol LenientStudyRuleStore {
        func find(_ code: String) -> LenientStudyRule?
        func save(_ item: LenientStudyRule)
        func remove(_ code: String) -> Bool
        func list() -> [LenientStudyRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientStudyRuleStore: LenientStudyRuleStore {
        var items: [String: LenientStudyRule]
        var order: [String]

        init(items: [String: LenientStudyRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientStudyRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientStudyRule) {
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

        func list() -> [LenientStudyRule] {
            var out: [LenientStudyRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientStudyRuleStore() -> any LenientStudyRuleStore {
        return MemoryLenientStudyRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientStudyRuleStore: LenientStudyRuleStore {
        var inner: MemoryLenientStudyRuleStore
        var cache: TTLCache<LenientStudyRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientStudyRuleStore, cache: TTLCache<LenientStudyRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientStudyRule? {
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

        func save(_ item: LenientStudyRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientStudyRule] {
            return inner.list()
        }
    }

    static func newCachedLenientStudyRuleStore(_ inner: MemoryLenientStudyRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientStudyRuleStore {
        return CachedLenientStudyRuleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient study rules. Empty fields match all.
    final class LenientStudyRuleQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientStudyRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientStudyRule]) -> [LenientStudyRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientStudyRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientStudyRules(_ store: any LenientStudyRuleStore, query: LenientStudyRuleQuery) -> [LenientStudyRule] {
        return query.apply(store.list())
    }
}

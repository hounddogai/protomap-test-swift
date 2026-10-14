import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result rules by code.
    protocol ResultRuleStore {
        func find(_ code: String) -> ResultRule?
        func save(_ item: ResultRule)
        func remove(_ code: String) -> Bool
        func list() -> [ResultRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultRuleStore: ResultRuleStore {
        var items: [String: ResultRule]
        var order: [String]

        init(items: [String: ResultRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultRule) {
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

        func list() -> [ResultRule] {
            var out: [ResultRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultRuleStore() -> any ResultRuleStore {
        return MemoryResultRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultRuleStore: ResultRuleStore {
        var inner: MemoryResultRuleStore
        var cache: TTLCache<ResultRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultRuleStore, cache: TTLCache<ResultRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultRule? {
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

        func save(_ item: ResultRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultRule] {
            return inner.list()
        }
    }

    static func newCachedResultRuleStore(_ inner: MemoryResultRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultRuleStore {
        return CachedResultRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result rules. Empty fields match all.
    final class ResultRuleQuery {
        var locale: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultRule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [ResultRule]) -> [ResultRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultRules(_ store: any ResultRuleStore, query: ResultRuleQuery) -> [ResultRule] {
        return query.apply(store.list())
    }
}

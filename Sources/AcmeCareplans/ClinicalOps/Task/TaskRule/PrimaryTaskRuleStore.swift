import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary task rules by code.
    protocol PrimaryTaskRuleStore {
        func find(_ code: String) -> PrimaryTaskRule?
        func save(_ item: PrimaryTaskRule)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryTaskRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryTaskRuleStore: PrimaryTaskRuleStore {
        var items: [String: PrimaryTaskRule]
        var order: [String]

        init(items: [String: PrimaryTaskRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryTaskRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryTaskRule) {
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

        func list() -> [PrimaryTaskRule] {
            var out: [PrimaryTaskRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryTaskRuleStore() -> any PrimaryTaskRuleStore {
        return MemoryPrimaryTaskRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryTaskRuleStore: PrimaryTaskRuleStore {
        var inner: MemoryPrimaryTaskRuleStore
        var cache: TTLCache<PrimaryTaskRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryTaskRuleStore, cache: TTLCache<PrimaryTaskRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryTaskRule? {
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

        func save(_ item: PrimaryTaskRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryTaskRule] {
            return inner.list()
        }
    }

    static func newCachedPrimaryTaskRuleStore(_ inner: MemoryPrimaryTaskRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryTaskRuleStore {
        return CachedPrimaryTaskRuleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary task rules. Empty fields match all.
    final class PrimaryTaskRuleQuery {
        var segment: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryTaskRule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [PrimaryTaskRule]) -> [PrimaryTaskRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryTaskRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryTaskRules(_ store: any PrimaryTaskRuleStore, query: PrimaryTaskRuleQuery) -> [PrimaryTaskRule] {
        return query.apply(store.list())
    }
}

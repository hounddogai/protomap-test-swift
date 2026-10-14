import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped transfer rules by code.
    protocol CappedTransferRuleStore {
        func find(_ code: String) -> CappedTransferRule?
        func save(_ item: CappedTransferRule)
        func remove(_ code: String) -> Bool
        func list() -> [CappedTransferRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedTransferRuleStore: CappedTransferRuleStore {
        var items: [String: CappedTransferRule]
        var order: [String]

        init(items: [String: CappedTransferRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedTransferRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedTransferRule) {
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

        func list() -> [CappedTransferRule] {
            var out: [CappedTransferRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedTransferRuleStore() -> any CappedTransferRuleStore {
        return MemoryCappedTransferRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedTransferRuleStore: CappedTransferRuleStore {
        var inner: MemoryCappedTransferRuleStore
        var cache: TTLCache<CappedTransferRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedTransferRuleStore, cache: TTLCache<CappedTransferRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedTransferRule? {
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

        func save(_ item: CappedTransferRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedTransferRule] {
            return inner.list()
        }
    }

    static func newCachedCappedTransferRuleStore(_ inner: MemoryCappedTransferRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedTransferRuleStore {
        return CachedCappedTransferRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped transfer rules. Empty fields match all.
    final class CappedTransferRuleQuery {
        var region: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedTransferRule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedTransferRule]) -> [CappedTransferRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedTransferRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedTransferRules(_ store: any CappedTransferRuleStore, query: CappedTransferRuleQuery) -> [CappedTransferRule] {
        return query.apply(store.list())
    }
}

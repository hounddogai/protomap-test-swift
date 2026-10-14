import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps transfer rules by code.
    protocol TransferRuleStore {
        func find(_ code: String) -> TransferRule?
        func save(_ item: TransferRule)
        func remove(_ code: String) -> Bool
        func list() -> [TransferRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTransferRuleStore: TransferRuleStore {
        var items: [String: TransferRule]
        var order: [String]

        init(items: [String: TransferRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TransferRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TransferRule) {
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

        func list() -> [TransferRule] {
            var out: [TransferRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTransferRuleStore() -> any TransferRuleStore {
        return MemoryTransferRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTransferRuleStore: TransferRuleStore {
        var inner: MemoryTransferRuleStore
        var cache: TTLCache<TransferRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryTransferRuleStore, cache: TTLCache<TransferRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TransferRule? {
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

        func save(_ item: TransferRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TransferRule] {
            return inner.list()
        }
    }

    static func newCachedTransferRuleStore(_ inner: MemoryTransferRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TransferRuleStore {
        return CachedTransferRuleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects transfer rules. Empty fields match all.
    final class TransferRuleQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TransferRule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TransferRule]) -> [TransferRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TransferRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTransferRules(_ store: any TransferRuleStore, query: TransferRuleQuery) -> [TransferRule] {
        return query.apply(store.list())
    }
}

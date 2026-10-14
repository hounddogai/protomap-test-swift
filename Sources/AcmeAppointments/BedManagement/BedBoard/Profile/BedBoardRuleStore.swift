import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board rules by code.
    protocol BedBoardRuleStore {
        func find(_ code: String) -> BedBoardRule?
        func save(_ item: BedBoardRule)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardRuleStore: BedBoardRuleStore {
        var items: [String: BedBoardRule]
        var order: [String]

        init(items: [String: BedBoardRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardRule) {
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

        func list() -> [BedBoardRule] {
            var out: [BedBoardRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardRuleStore() -> any BedBoardRuleStore {
        return MemoryBedBoardRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardRuleStore: BedBoardRuleStore {
        var inner: MemoryBedBoardRuleStore
        var cache: TTLCache<BedBoardRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardRuleStore, cache: TTLCache<BedBoardRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardRule? {
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

        func save(_ item: BedBoardRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardRule] {
            return inner.list()
        }
    }

    static func newCachedBedBoardRuleStore(_ inner: MemoryBedBoardRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardRuleStore {
        return CachedBedBoardRuleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board rules. Empty fields match all.
    final class BedBoardRuleQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [BedBoardRule]) -> [BedBoardRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardRules(_ store: any BedBoardRuleStore, query: BedBoardRuleQuery) -> [BedBoardRule] {
        return query.apply(store.list())
    }
}

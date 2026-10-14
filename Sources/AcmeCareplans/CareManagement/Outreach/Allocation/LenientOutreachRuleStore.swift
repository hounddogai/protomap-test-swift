import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient outreach rules by code.
    protocol LenientOutreachRuleStore {
        func find(_ code: String) -> LenientOutreachRule?
        func save(_ item: LenientOutreachRule)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOutreachRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOutreachRuleStore: LenientOutreachRuleStore {
        var items: [String: LenientOutreachRule]
        var order: [String]

        init(items: [String: LenientOutreachRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOutreachRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOutreachRule) {
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

        func list() -> [LenientOutreachRule] {
            var out: [LenientOutreachRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOutreachRuleStore() -> any LenientOutreachRuleStore {
        return MemoryLenientOutreachRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOutreachRuleStore: LenientOutreachRuleStore {
        var inner: MemoryLenientOutreachRuleStore
        var cache: TTLCache<LenientOutreachRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOutreachRuleStore, cache: TTLCache<LenientOutreachRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOutreachRule? {
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

        func save(_ item: LenientOutreachRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOutreachRule] {
            return inner.list()
        }
    }

    static func newCachedLenientOutreachRuleStore(_ inner: MemoryLenientOutreachRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOutreachRuleStore {
        return CachedLenientOutreachRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient outreach rules. Empty fields match all.
    final class LenientOutreachRuleQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOutreachRule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientOutreachRule]) -> [LenientOutreachRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOutreachRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOutreachRules(_ store: any LenientOutreachRuleStore, query: LenientOutreachRuleQuery) -> [LenientOutreachRule] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach rules by code.
    protocol OutreachRuleStore {
        func find(_ code: String) -> OutreachRule?
        func save(_ item: OutreachRule)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachRule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachRuleStore: OutreachRuleStore {
        var items: [String: OutreachRule]
        var order: [String]

        init(items: [String: OutreachRule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachRule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachRule) {
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

        func list() -> [OutreachRule] {
            var out: [OutreachRule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachRuleStore() -> any OutreachRuleStore {
        return MemoryOutreachRuleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachRuleStore: OutreachRuleStore {
        var inner: MemoryOutreachRuleStore
        var cache: TTLCache<OutreachRule>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachRuleStore, cache: TTLCache<OutreachRule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachRule? {
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

        func save(_ item: OutreachRule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachRule] {
            return inner.list()
        }
    }

    static func newCachedOutreachRuleStore(_ inner: MemoryOutreachRuleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachRuleStore {
        return CachedOutreachRuleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach rules. Empty fields match all.
    final class OutreachRuleQuery {
        var ward: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachRule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [OutreachRule]) -> [OutreachRule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachRule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachRules(_ store: any OutreachRuleStore, query: OutreachRuleQuery) -> [OutreachRule] {
        return query.apply(store.list())
    }
}

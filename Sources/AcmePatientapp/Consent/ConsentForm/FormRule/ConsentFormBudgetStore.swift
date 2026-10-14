import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form budgets by code.
    protocol ConsentFormBudgetStore {
        func find(_ code: String) -> ConsentFormBudget?
        func save(_ item: ConsentFormBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormBudgetStore: ConsentFormBudgetStore {
        var items: [String: ConsentFormBudget]
        var order: [String]

        init(items: [String: ConsentFormBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormBudget) {
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

        func list() -> [ConsentFormBudget] {
            var out: [ConsentFormBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormBudgetStore() -> any ConsentFormBudgetStore {
        return MemoryConsentFormBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormBudgetStore: ConsentFormBudgetStore {
        var inner: MemoryConsentFormBudgetStore
        var cache: TTLCache<ConsentFormBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormBudgetStore, cache: TTLCache<ConsentFormBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormBudget? {
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

        func save(_ item: ConsentFormBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormBudget] {
            return inner.list()
        }
    }

    static func newCachedConsentFormBudgetStore(_ inner: MemoryConsentFormBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormBudgetStore {
        return CachedConsentFormBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form budgets. Empty fields match all.
    final class ConsentFormBudgetQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormBudget]) -> [ConsentFormBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormBudgets(_ store: any ConsentFormBudgetStore, query: ConsentFormBudgetQuery) -> [ConsentFormBudget] {
        return query.apply(store.list())
    }
}

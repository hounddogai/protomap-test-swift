import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist agreements by code.
    protocol WorklistAgreementStore {
        func find(_ code: String) -> WorklistAgreement?
        func save(_ item: WorklistAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistAgreementStore: WorklistAgreementStore {
        var items: [String: WorklistAgreement]
        var order: [String]

        init(items: [String: WorklistAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistAgreement) {
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

        func list() -> [WorklistAgreement] {
            var out: [WorklistAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistAgreementStore() -> any WorklistAgreementStore {
        return MemoryWorklistAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistAgreementStore: WorklistAgreementStore {
        var inner: MemoryWorklistAgreementStore
        var cache: TTLCache<WorklistAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistAgreementStore, cache: TTLCache<WorklistAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistAgreement? {
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

        func save(_ item: WorklistAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistAgreement] {
            return inner.list()
        }
    }

    static func newCachedWorklistAgreementStore(_ inner: MemoryWorklistAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistAgreementStore {
        return CachedWorklistAgreementStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist agreements. Empty fields match all.
    final class WorklistAgreementQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistAgreement) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistAgreement]) -> [WorklistAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistAgreements(_ store: any WorklistAgreementStore, query: WorklistAgreementQuery) -> [WorklistAgreement] {
        return query.apply(store.list())
    }
}

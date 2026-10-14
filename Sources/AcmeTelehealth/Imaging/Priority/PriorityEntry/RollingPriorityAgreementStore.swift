import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling priority agreements by code.
    protocol RollingPriorityAgreementStore {
        func find(_ code: String) -> RollingPriorityAgreement?
        func save(_ item: RollingPriorityAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [RollingPriorityAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingPriorityAgreementStore: RollingPriorityAgreementStore {
        var items: [String: RollingPriorityAgreement]
        var order: [String]

        init(items: [String: RollingPriorityAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingPriorityAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingPriorityAgreement) {
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

        func list() -> [RollingPriorityAgreement] {
            var out: [RollingPriorityAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingPriorityAgreementStore() -> any RollingPriorityAgreementStore {
        return MemoryRollingPriorityAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingPriorityAgreementStore: RollingPriorityAgreementStore {
        var inner: MemoryRollingPriorityAgreementStore
        var cache: TTLCache<RollingPriorityAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingPriorityAgreementStore, cache: TTLCache<RollingPriorityAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingPriorityAgreement? {
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

        func save(_ item: RollingPriorityAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingPriorityAgreement] {
            return inner.list()
        }
    }

    static func newCachedRollingPriorityAgreementStore(_ inner: MemoryRollingPriorityAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingPriorityAgreementStore {
        return CachedRollingPriorityAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling priority agreements. Empty fields match all.
    final class RollingPriorityAgreementQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingPriorityAgreement) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RollingPriorityAgreement]) -> [RollingPriorityAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingPriorityAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingPriorityAgreements(_ store: any RollingPriorityAgreementStore, query: RollingPriorityAgreementQuery) -> [RollingPriorityAgreement] {
        return query.apply(store.list())
    }
}

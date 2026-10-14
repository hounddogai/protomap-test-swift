import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global priority agreements by code.
    protocol GlobalPriorityAgreementStore {
        func find(_ code: String) -> GlobalPriorityAgreement?
        func save(_ item: GlobalPriorityAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalPriorityAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalPriorityAgreementStore: GlobalPriorityAgreementStore {
        var items: [String: GlobalPriorityAgreement]
        var order: [String]

        init(items: [String: GlobalPriorityAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalPriorityAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalPriorityAgreement) {
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

        func list() -> [GlobalPriorityAgreement] {
            var out: [GlobalPriorityAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalPriorityAgreementStore() -> any GlobalPriorityAgreementStore {
        return MemoryGlobalPriorityAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalPriorityAgreementStore: GlobalPriorityAgreementStore {
        var inner: MemoryGlobalPriorityAgreementStore
        var cache: TTLCache<GlobalPriorityAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalPriorityAgreementStore, cache: TTLCache<GlobalPriorityAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalPriorityAgreement? {
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

        func save(_ item: GlobalPriorityAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalPriorityAgreement] {
            return inner.list()
        }
    }

    static func newCachedGlobalPriorityAgreementStore(_ inner: MemoryGlobalPriorityAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalPriorityAgreementStore {
        return CachedGlobalPriorityAgreementStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global priority agreements. Empty fields match all.
    final class GlobalPriorityAgreementQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalPriorityAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalPriorityAgreement]) -> [GlobalPriorityAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalPriorityAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalPriorityAgreements(_ store: any GlobalPriorityAgreementStore, query: GlobalPriorityAgreementQuery) -> [GlobalPriorityAgreement] {
        return query.apply(store.list())
    }
}

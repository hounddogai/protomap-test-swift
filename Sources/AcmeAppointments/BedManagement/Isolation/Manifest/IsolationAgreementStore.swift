import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation agreements by code.
    protocol IsolationAgreementStore {
        func find(_ code: String) -> IsolationAgreement?
        func save(_ item: IsolationAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationAgreementStore: IsolationAgreementStore {
        var items: [String: IsolationAgreement]
        var order: [String]

        init(items: [String: IsolationAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationAgreement) {
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

        func list() -> [IsolationAgreement] {
            var out: [IsolationAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationAgreementStore() -> any IsolationAgreementStore {
        return MemoryIsolationAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationAgreementStore: IsolationAgreementStore {
        var inner: MemoryIsolationAgreementStore
        var cache: TTLCache<IsolationAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationAgreementStore, cache: TTLCache<IsolationAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationAgreement? {
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

        func save(_ item: IsolationAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationAgreement] {
            return inner.list()
        }
    }

    static func newCachedIsolationAgreementStore(_ inner: MemoryIsolationAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationAgreementStore {
        return CachedIsolationAgreementStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation agreements. Empty fields match all.
    final class IsolationAgreementQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationAgreement) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationAgreement]) -> [IsolationAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationAgreements(_ store: any IsolationAgreementStore, query: IsolationAgreementQuery) -> [IsolationAgreement] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization records by code.
    protocol AuthorizationRecordStore {
        func find(_ code: String) -> AuthorizationRecord?
        func save(_ item: AuthorizationRecord)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationRecordStore: AuthorizationRecordStore {
        var items: [String: AuthorizationRecord]
        var order: [String]

        init(items: [String: AuthorizationRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationRecord) {
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

        func list() -> [AuthorizationRecord] {
            var out: [AuthorizationRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationRecordStore() -> any AuthorizationRecordStore {
        return MemoryAuthorizationRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationRecordStore: AuthorizationRecordStore {
        var inner: MemoryAuthorizationRecordStore
        var cache: TTLCache<AuthorizationRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationRecordStore, cache: TTLCache<AuthorizationRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationRecord? {
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

        func save(_ item: AuthorizationRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationRecord] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationRecordStore(_ inner: MemoryAuthorizationRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationRecordStore {
        return CachedAuthorizationRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization records. Empty fields match all.
    final class AuthorizationRecordQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationRecord) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationRecord]) -> [AuthorizationRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationRecords(_ store: any AuthorizationRecordStore, query: AuthorizationRecordQuery) -> [AuthorizationRecord] {
        return query.apply(store.list())
    }
}

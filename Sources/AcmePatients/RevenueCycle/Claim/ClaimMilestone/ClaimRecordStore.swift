import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim records by code.
    protocol ClaimRecordStore {
        func find(_ code: String) -> ClaimRecord?
        func save(_ item: ClaimRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimRecordStore: ClaimRecordStore {
        var items: [String: ClaimRecord]
        var order: [String]

        init(items: [String: ClaimRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimRecord) {
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

        func list() -> [ClaimRecord] {
            var out: [ClaimRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimRecordStore() -> any ClaimRecordStore {
        return MemoryClaimRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimRecordStore: ClaimRecordStore {
        var inner: MemoryClaimRecordStore
        var cache: TTLCache<ClaimRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimRecordStore, cache: TTLCache<ClaimRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimRecord? {
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

        func save(_ item: ClaimRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimRecord] {
            return inner.list()
        }
    }

    static func newCachedClaimRecordStore(_ inner: MemoryClaimRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimRecordStore {
        return CachedClaimRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim records. Empty fields match all.
    final class ClaimRecordQuery {
        var category: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minLimit: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ClaimRecord]) -> [ClaimRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimRecords(_ store: any ClaimRecordStore, query: ClaimRecordQuery) -> [ClaimRecord] {
        return query.apply(store.list())
    }
}

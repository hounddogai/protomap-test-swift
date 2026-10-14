import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential records by code.
    protocol CredentialRecordStore {
        func find(_ code: String) -> CredentialRecord?
        func save(_ item: CredentialRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialRecordStore: CredentialRecordStore {
        var items: [String: CredentialRecord]
        var order: [String]

        init(items: [String: CredentialRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialRecord) {
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

        func list() -> [CredentialRecord] {
            var out: [CredentialRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialRecordStore() -> any CredentialRecordStore {
        return MemoryCredentialRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialRecordStore: CredentialRecordStore {
        var inner: MemoryCredentialRecordStore
        var cache: TTLCache<CredentialRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialRecordStore, cache: TTLCache<CredentialRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialRecord? {
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

        func save(_ item: CredentialRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialRecord] {
            return inner.list()
        }
    }

    static func newCachedCredentialRecordStore(_ inner: MemoryCredentialRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialRecordStore {
        return CachedCredentialRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential records. Empty fields match all.
    final class CredentialRecordQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialRecord) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialRecord]) -> [CredentialRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialRecords(_ store: any CredentialRecordStore, query: CredentialRecordQuery) -> [CredentialRecord] {
        return query.apply(store.list())
    }
}

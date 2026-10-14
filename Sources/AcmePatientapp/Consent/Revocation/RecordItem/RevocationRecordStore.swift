import AcmePlatform
import Foundation

extension Consent {
    /// Keeps revocation records by code.
    protocol RevocationRecordStore {
        func find(_ code: String) -> RevocationRecord?
        func save(_ item: RevocationRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RevocationRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRevocationRecordStore: RevocationRecordStore {
        var items: [String: RevocationRecord]
        var order: [String]

        init(items: [String: RevocationRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RevocationRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RevocationRecord) {
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

        func list() -> [RevocationRecord] {
            var out: [RevocationRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRevocationRecordStore() -> any RevocationRecordStore {
        return MemoryRevocationRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRevocationRecordStore: RevocationRecordStore {
        var inner: MemoryRevocationRecordStore
        var cache: TTLCache<RevocationRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRevocationRecordStore, cache: TTLCache<RevocationRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RevocationRecord? {
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

        func save(_ item: RevocationRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RevocationRecord] {
            return inner.list()
        }
    }

    static func newCachedRevocationRecordStore(_ inner: MemoryRevocationRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RevocationRecordStore {
        return CachedRevocationRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects revocation records. Empty fields match all.
    final class RevocationRecordQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RevocationRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RevocationRecord]) -> [RevocationRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RevocationRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRevocationRecords(_ store: any RevocationRecordStore, query: RevocationRecordQuery) -> [RevocationRecord] {
        return query.apply(store.list())
    }
}

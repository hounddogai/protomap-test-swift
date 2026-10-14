import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps lenient claim records by code.
    protocol LenientClaimRecordStore {
        func find(_ code: String) -> LenientClaimRecord?
        func save(_ item: LenientClaimRecord)
        func remove(_ code: String) -> Bool
        func list() -> [LenientClaimRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientClaimRecordStore: LenientClaimRecordStore {
        var items: [String: LenientClaimRecord]
        var order: [String]

        init(items: [String: LenientClaimRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientClaimRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientClaimRecord) {
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

        func list() -> [LenientClaimRecord] {
            var out: [LenientClaimRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientClaimRecordStore() -> any LenientClaimRecordStore {
        return MemoryLenientClaimRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientClaimRecordStore: LenientClaimRecordStore {
        var inner: MemoryLenientClaimRecordStore
        var cache: TTLCache<LenientClaimRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientClaimRecordStore, cache: TTLCache<LenientClaimRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientClaimRecord? {
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

        func save(_ item: LenientClaimRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientClaimRecord] {
            return inner.list()
        }
    }

    static func newCachedLenientClaimRecordStore(_ inner: MemoryLenientClaimRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientClaimRecordStore {
        return CachedLenientClaimRecordStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient claim records. Empty fields match all.
    final class LenientClaimRecordQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientClaimRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientClaimRecord]) -> [LenientClaimRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientClaimRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientClaimRecords(_ store: any LenientClaimRecordStore, query: LenientClaimRecordQuery) -> [LenientClaimRecord] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form records by code.
    protocol ConsentFormRecordStore {
        func find(_ code: String) -> ConsentFormRecord?
        func save(_ item: ConsentFormRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormRecordStore: ConsentFormRecordStore {
        var items: [String: ConsentFormRecord]
        var order: [String]

        init(items: [String: ConsentFormRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormRecord) {
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

        func list() -> [ConsentFormRecord] {
            var out: [ConsentFormRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormRecordStore() -> any ConsentFormRecordStore {
        return MemoryConsentFormRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormRecordStore: ConsentFormRecordStore {
        var inner: MemoryConsentFormRecordStore
        var cache: TTLCache<ConsentFormRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormRecordStore, cache: TTLCache<ConsentFormRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormRecord? {
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

        func save(_ item: ConsentFormRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormRecord] {
            return inner.list()
        }
    }

    static func newCachedConsentFormRecordStore(_ inner: MemoryConsentFormRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormRecordStore {
        return CachedConsentFormRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form records. Empty fields match all.
    final class ConsentFormRecordQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ConsentFormRecord) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ConsentFormRecord]) -> [ConsentFormRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormRecords(_ store: any ConsentFormRecordStore, query: ConsentFormRecordQuery) -> [ConsentFormRecord] {
        return query.apply(store.list())
    }
}

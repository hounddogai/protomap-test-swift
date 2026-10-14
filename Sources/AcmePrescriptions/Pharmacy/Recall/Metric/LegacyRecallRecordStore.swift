import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy recall records by code.
    protocol LegacyRecallRecordStore {
        func find(_ code: String) -> LegacyRecallRecord?
        func save(_ item: LegacyRecallRecord)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyRecallRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyRecallRecordStore: LegacyRecallRecordStore {
        var items: [String: LegacyRecallRecord]
        var order: [String]

        init(items: [String: LegacyRecallRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyRecallRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyRecallRecord) {
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

        func list() -> [LegacyRecallRecord] {
            var out: [LegacyRecallRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyRecallRecordStore() -> any LegacyRecallRecordStore {
        return MemoryLegacyRecallRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyRecallRecordStore: LegacyRecallRecordStore {
        var inner: MemoryLegacyRecallRecordStore
        var cache: TTLCache<LegacyRecallRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyRecallRecordStore, cache: TTLCache<LegacyRecallRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyRecallRecord? {
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

        func save(_ item: LegacyRecallRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyRecallRecord] {
            return inner.list()
        }
    }

    static func newCachedLegacyRecallRecordStore(_ inner: MemoryLegacyRecallRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyRecallRecordStore {
        return CachedLegacyRecallRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy recall records. Empty fields match all.
    final class LegacyRecallRecordQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyRecallRecord) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyRecallRecord]) -> [LegacyRecallRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyRecallRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyRecallRecords(_ store: any LegacyRecallRecordStore, query: LegacyRecallRecordQuery) -> [LegacyRecallRecord] {
        return query.apply(store.list())
    }
}

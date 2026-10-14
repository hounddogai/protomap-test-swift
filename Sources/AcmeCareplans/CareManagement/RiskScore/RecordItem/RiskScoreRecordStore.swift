import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score records by code.
    protocol RiskScoreRecordStore {
        func find(_ code: String) -> RiskScoreRecord?
        func save(_ item: RiskScoreRecord)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreRecordStore: RiskScoreRecordStore {
        var items: [String: RiskScoreRecord]
        var order: [String]

        init(items: [String: RiskScoreRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreRecord) {
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

        func list() -> [RiskScoreRecord] {
            var out: [RiskScoreRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreRecordStore() -> any RiskScoreRecordStore {
        return MemoryRiskScoreRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreRecordStore: RiskScoreRecordStore {
        var inner: MemoryRiskScoreRecordStore
        var cache: TTLCache<RiskScoreRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreRecordStore, cache: TTLCache<RiskScoreRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreRecord? {
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

        func save(_ item: RiskScoreRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreRecord] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreRecordStore(_ inner: MemoryRiskScoreRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreRecordStore {
        return CachedRiskScoreRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score records. Empty fields match all.
    final class RiskScoreRecordQuery {
        var channel: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreRecord) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreRecord]) -> [RiskScoreRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreRecords(_ store: any RiskScoreRecordStore, query: RiskScoreRecordQuery) -> [RiskScoreRecord] {
        return query.apply(store.list())
    }
}

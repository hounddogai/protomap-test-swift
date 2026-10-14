import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global skill mix records by code.
    protocol GlobalSkillMixRecordStore {
        func find(_ code: String) -> GlobalSkillMixRecord?
        func save(_ item: GlobalSkillMixRecord)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSkillMixRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSkillMixRecordStore: GlobalSkillMixRecordStore {
        var items: [String: GlobalSkillMixRecord]
        var order: [String]

        init(items: [String: GlobalSkillMixRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSkillMixRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSkillMixRecord) {
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

        func list() -> [GlobalSkillMixRecord] {
            var out: [GlobalSkillMixRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSkillMixRecordStore() -> any GlobalSkillMixRecordStore {
        return MemoryGlobalSkillMixRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSkillMixRecordStore: GlobalSkillMixRecordStore {
        var inner: MemoryGlobalSkillMixRecordStore
        var cache: TTLCache<GlobalSkillMixRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSkillMixRecordStore, cache: TTLCache<GlobalSkillMixRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSkillMixRecord? {
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

        func save(_ item: GlobalSkillMixRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSkillMixRecord] {
            return inner.list()
        }
    }

    static func newCachedGlobalSkillMixRecordStore(_ inner: MemoryGlobalSkillMixRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSkillMixRecordStore {
        return CachedGlobalSkillMixRecordStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global skill mix records. Empty fields match all.
    final class GlobalSkillMixRecordQuery {
        var source: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minBudget: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSkillMixRecord) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [GlobalSkillMixRecord]) -> [GlobalSkillMixRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSkillMixRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSkillMixRecords(_ store: any GlobalSkillMixRecordStore, query: GlobalSkillMixRecordQuery) -> [GlobalSkillMixRecord] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict skill mix ledgers by code.
    protocol StrictSkillMixLedgerStore {
        func find(_ code: String) -> StrictSkillMixLedger?
        func save(_ item: StrictSkillMixLedger)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSkillMixLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSkillMixLedgerStore: StrictSkillMixLedgerStore {
        var items: [String: StrictSkillMixLedger]
        var order: [String]

        init(items: [String: StrictSkillMixLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSkillMixLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSkillMixLedger) {
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

        func list() -> [StrictSkillMixLedger] {
            var out: [StrictSkillMixLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSkillMixLedgerStore() -> any StrictSkillMixLedgerStore {
        return MemoryStrictSkillMixLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSkillMixLedgerStore: StrictSkillMixLedgerStore {
        var inner: MemoryStrictSkillMixLedgerStore
        var cache: TTLCache<StrictSkillMixLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSkillMixLedgerStore, cache: TTLCache<StrictSkillMixLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSkillMixLedger? {
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

        func save(_ item: StrictSkillMixLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSkillMixLedger] {
            return inner.list()
        }
    }

    static func newCachedStrictSkillMixLedgerStore(_ inner: MemoryStrictSkillMixLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSkillMixLedgerStore {
        return CachedStrictSkillMixLedgerStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict skill mix ledgers. Empty fields match all.
    final class StrictSkillMixLedgerQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSkillMixLedger) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSkillMixLedger]) -> [StrictSkillMixLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSkillMixLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSkillMixLedgers(_ store: any StrictSkillMixLedgerStore, query: StrictSkillMixLedgerQuery) -> [StrictSkillMixLedger] {
        return query.apply(store.list())
    }
}

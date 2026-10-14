import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary skill mix cycles by code.
    protocol PrimarySkillMixCycleStore {
        func find(_ code: String) -> PrimarySkillMixCycle?
        func save(_ item: PrimarySkillMixCycle)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySkillMixCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySkillMixCycleStore: PrimarySkillMixCycleStore {
        var items: [String: PrimarySkillMixCycle]
        var order: [String]

        init(items: [String: PrimarySkillMixCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySkillMixCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySkillMixCycle) {
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

        func list() -> [PrimarySkillMixCycle] {
            var out: [PrimarySkillMixCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySkillMixCycleStore() -> any PrimarySkillMixCycleStore {
        return MemoryPrimarySkillMixCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySkillMixCycleStore: PrimarySkillMixCycleStore {
        var inner: MemoryPrimarySkillMixCycleStore
        var cache: TTLCache<PrimarySkillMixCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySkillMixCycleStore, cache: TTLCache<PrimarySkillMixCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySkillMixCycle? {
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

        func save(_ item: PrimarySkillMixCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySkillMixCycle] {
            return inner.list()
        }
    }

    static func newCachedPrimarySkillMixCycleStore(_ inner: MemoryPrimarySkillMixCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySkillMixCycleStore {
        return CachedPrimarySkillMixCycleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary skill mix cycles. Empty fields match all.
    final class PrimarySkillMixCycleQuery {
        var locale: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySkillMixCycle) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySkillMixCycle]) -> [PrimarySkillMixCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySkillMixCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySkillMixCycles(_ store: any PrimarySkillMixCycleStore, query: PrimarySkillMixCycleQuery) -> [PrimarySkillMixCycle] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix windows by code.
    protocol SkillMixWindowStore {
        func find(_ code: String) -> SkillMixWindow?
        func save(_ item: SkillMixWindow)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixWindowStore: SkillMixWindowStore {
        var items: [String: SkillMixWindow]
        var order: [String]

        init(items: [String: SkillMixWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixWindow) {
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

        func list() -> [SkillMixWindow] {
            var out: [SkillMixWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixWindowStore() -> any SkillMixWindowStore {
        return MemorySkillMixWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixWindowStore: SkillMixWindowStore {
        var inner: MemorySkillMixWindowStore
        var cache: TTLCache<SkillMixWindow>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixWindowStore, cache: TTLCache<SkillMixWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixWindow? {
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

        func save(_ item: SkillMixWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixWindow] {
            return inner.list()
        }
    }

    static func newCachedSkillMixWindowStore(_ inner: MemorySkillMixWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixWindowStore {
        return CachedSkillMixWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix windows. Empty fields match all.
    final class SkillMixWindowQuery {
        var source: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixWindow) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixWindow]) -> [SkillMixWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixWindows(_ store: any SkillMixWindowStore, query: SkillMixWindowQuery) -> [SkillMixWindow] {
        return query.apply(store.list())
    }
}

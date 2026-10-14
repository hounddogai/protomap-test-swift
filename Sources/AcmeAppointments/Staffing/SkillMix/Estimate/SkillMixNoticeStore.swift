import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix notices by code.
    protocol SkillMixNoticeStore {
        func find(_ code: String) -> SkillMixNotice?
        func save(_ item: SkillMixNotice)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixNoticeStore: SkillMixNoticeStore {
        var items: [String: SkillMixNotice]
        var order: [String]

        init(items: [String: SkillMixNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixNotice) {
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

        func list() -> [SkillMixNotice] {
            var out: [SkillMixNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixNoticeStore() -> any SkillMixNoticeStore {
        return MemorySkillMixNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixNoticeStore: SkillMixNoticeStore {
        var inner: MemorySkillMixNoticeStore
        var cache: TTLCache<SkillMixNotice>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixNoticeStore, cache: TTLCache<SkillMixNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixNotice? {
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

        func save(_ item: SkillMixNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixNotice] {
            return inner.list()
        }
    }

    static func newCachedSkillMixNoticeStore(_ inner: MemorySkillMixNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixNoticeStore {
        return CachedSkillMixNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix notices. Empty fields match all.
    final class SkillMixNoticeQuery {
        var category: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixNotice) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [SkillMixNotice]) -> [SkillMixNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixNotices(_ store: any SkillMixNoticeStore, query: SkillMixNoticeQuery) -> [SkillMixNotice] {
        return query.apply(store.list())
    }
}

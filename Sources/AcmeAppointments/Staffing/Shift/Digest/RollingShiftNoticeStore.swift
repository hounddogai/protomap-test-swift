import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling shift notices by code.
    protocol RollingShiftNoticeStore {
        func find(_ code: String) -> RollingShiftNotice?
        func save(_ item: RollingShiftNotice)
        func remove(_ code: String) -> Bool
        func list() -> [RollingShiftNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingShiftNoticeStore: RollingShiftNoticeStore {
        var items: [String: RollingShiftNotice]
        var order: [String]

        init(items: [String: RollingShiftNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingShiftNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingShiftNotice) {
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

        func list() -> [RollingShiftNotice] {
            var out: [RollingShiftNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingShiftNoticeStore() -> any RollingShiftNoticeStore {
        return MemoryRollingShiftNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingShiftNoticeStore: RollingShiftNoticeStore {
        var inner: MemoryRollingShiftNoticeStore
        var cache: TTLCache<RollingShiftNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingShiftNoticeStore, cache: TTLCache<RollingShiftNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingShiftNotice? {
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

        func save(_ item: RollingShiftNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingShiftNotice] {
            return inner.list()
        }
    }

    static func newCachedRollingShiftNoticeStore(_ inner: MemoryRollingShiftNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingShiftNoticeStore {
        return CachedRollingShiftNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling shift notices. Empty fields match all.
    final class RollingShiftNoticeQuery {
        var label: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingShiftNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingShiftNotice]) -> [RollingShiftNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingShiftNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingShiftNotices(_ store: any RollingShiftNoticeStore, query: RollingShiftNoticeQuery) -> [RollingShiftNotice] {
        return query.apply(store.list())
    }
}

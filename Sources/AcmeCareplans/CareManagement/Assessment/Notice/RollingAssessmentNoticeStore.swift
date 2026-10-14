import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling assessment notices by code.
    protocol RollingAssessmentNoticeStore {
        func find(_ code: String) -> RollingAssessmentNotice?
        func save(_ item: RollingAssessmentNotice)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAssessmentNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAssessmentNoticeStore: RollingAssessmentNoticeStore {
        var items: [String: RollingAssessmentNotice]
        var order: [String]

        init(items: [String: RollingAssessmentNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAssessmentNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAssessmentNotice) {
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

        func list() -> [RollingAssessmentNotice] {
            var out: [RollingAssessmentNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAssessmentNoticeStore() -> any RollingAssessmentNoticeStore {
        return MemoryRollingAssessmentNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAssessmentNoticeStore: RollingAssessmentNoticeStore {
        var inner: MemoryRollingAssessmentNoticeStore
        var cache: TTLCache<RollingAssessmentNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAssessmentNoticeStore, cache: TTLCache<RollingAssessmentNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAssessmentNotice? {
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

        func save(_ item: RollingAssessmentNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAssessmentNotice] {
            return inner.list()
        }
    }

    static func newCachedRollingAssessmentNoticeStore(_ inner: MemoryRollingAssessmentNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAssessmentNoticeStore {
        return CachedRollingAssessmentNoticeStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling assessment notices. Empty fields match all.
    final class RollingAssessmentNoticeQuery {
        var ward: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVersion: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAssessmentNotice) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAssessmentNotice]) -> [RollingAssessmentNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAssessmentNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAssessmentNotices(_ store: any RollingAssessmentNoticeStore, query: RollingAssessmentNoticeQuery) -> [RollingAssessmentNotice] {
        return query.apply(store.list())
    }
}

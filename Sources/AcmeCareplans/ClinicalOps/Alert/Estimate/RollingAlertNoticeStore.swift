import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling alert notices by code.
    protocol RollingAlertNoticeStore {
        func find(_ code: String) -> RollingAlertNotice?
        func save(_ item: RollingAlertNotice)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAlertNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAlertNoticeStore: RollingAlertNoticeStore {
        var items: [String: RollingAlertNotice]
        var order: [String]

        init(items: [String: RollingAlertNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAlertNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAlertNotice) {
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

        func list() -> [RollingAlertNotice] {
            var out: [RollingAlertNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAlertNoticeStore() -> any RollingAlertNoticeStore {
        return MemoryRollingAlertNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAlertNoticeStore: RollingAlertNoticeStore {
        var inner: MemoryRollingAlertNoticeStore
        var cache: TTLCache<RollingAlertNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAlertNoticeStore, cache: TTLCache<RollingAlertNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAlertNotice? {
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

        func save(_ item: RollingAlertNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAlertNotice] {
            return inner.list()
        }
    }

    static func newCachedRollingAlertNoticeStore(_ inner: MemoryRollingAlertNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAlertNoticeStore {
        return CachedRollingAlertNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling alert notices. Empty fields match all.
    final class RollingAlertNoticeQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAlertNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAlertNotice]) -> [RollingAlertNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAlertNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAlertNotices(_ store: any RollingAlertNoticeStore, query: RollingAlertNoticeQuery) -> [RollingAlertNotice] {
        return query.apply(store.list())
    }
}

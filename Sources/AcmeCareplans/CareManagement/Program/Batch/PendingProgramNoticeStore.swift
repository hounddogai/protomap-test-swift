import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending program notices by code.
    protocol PendingProgramNoticeStore {
        func find(_ code: String) -> PendingProgramNotice?
        func save(_ item: PendingProgramNotice)
        func remove(_ code: String) -> Bool
        func list() -> [PendingProgramNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingProgramNoticeStore: PendingProgramNoticeStore {
        var items: [String: PendingProgramNotice]
        var order: [String]

        init(items: [String: PendingProgramNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingProgramNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingProgramNotice) {
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

        func list() -> [PendingProgramNotice] {
            var out: [PendingProgramNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingProgramNoticeStore() -> any PendingProgramNoticeStore {
        return MemoryPendingProgramNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingProgramNoticeStore: PendingProgramNoticeStore {
        var inner: MemoryPendingProgramNoticeStore
        var cache: TTLCache<PendingProgramNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingProgramNoticeStore, cache: TTLCache<PendingProgramNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingProgramNotice? {
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

        func save(_ item: PendingProgramNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingProgramNotice] {
            return inner.list()
        }
    }

    static func newCachedPendingProgramNoticeStore(_ inner: MemoryPendingProgramNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingProgramNoticeStore {
        return CachedPendingProgramNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending program notices. Empty fields match all.
    final class PendingProgramNoticeQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingProgramNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingProgramNotice]) -> [PendingProgramNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingProgramNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingProgramNotices(_ store: any PendingProgramNoticeStore, query: PendingProgramNoticeQuery) -> [PendingProgramNotice] {
        return query.apply(store.list())
    }
}

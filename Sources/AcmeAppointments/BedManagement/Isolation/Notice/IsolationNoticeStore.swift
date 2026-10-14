import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation notices by code.
    protocol IsolationNoticeStore {
        func find(_ code: String) -> IsolationNotice?
        func save(_ item: IsolationNotice)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationNoticeStore: IsolationNoticeStore {
        var items: [String: IsolationNotice]
        var order: [String]

        init(items: [String: IsolationNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationNotice) {
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

        func list() -> [IsolationNotice] {
            var out: [IsolationNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationNoticeStore() -> any IsolationNoticeStore {
        return MemoryIsolationNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationNoticeStore: IsolationNoticeStore {
        var inner: MemoryIsolationNoticeStore
        var cache: TTLCache<IsolationNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationNoticeStore, cache: TTLCache<IsolationNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationNotice? {
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

        func save(_ item: IsolationNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationNotice] {
            return inner.list()
        }
    }

    static func newCachedIsolationNoticeStore(_ inner: MemoryIsolationNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationNoticeStore {
        return CachedIsolationNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation notices. Empty fields match all.
    final class IsolationNoticeQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationNotice) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationNotice]) -> [IsolationNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationNotices(_ store: any IsolationNoticeStore, query: IsolationNoticeQuery) -> [IsolationNotice] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps tiered dispense notices by code.
    protocol TieredDispenseNoticeStore {
        func find(_ code: String) -> TieredDispenseNotice?
        func save(_ item: TieredDispenseNotice)
        func remove(_ code: String) -> Bool
        func list() -> [TieredDispenseNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredDispenseNoticeStore: TieredDispenseNoticeStore {
        var items: [String: TieredDispenseNotice]
        var order: [String]

        init(items: [String: TieredDispenseNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredDispenseNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredDispenseNotice) {
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

        func list() -> [TieredDispenseNotice] {
            var out: [TieredDispenseNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredDispenseNoticeStore() -> any TieredDispenseNoticeStore {
        return MemoryTieredDispenseNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredDispenseNoticeStore: TieredDispenseNoticeStore {
        var inner: MemoryTieredDispenseNoticeStore
        var cache: TTLCache<TieredDispenseNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredDispenseNoticeStore, cache: TTLCache<TieredDispenseNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredDispenseNotice? {
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

        func save(_ item: TieredDispenseNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredDispenseNotice] {
            return inner.list()
        }
    }

    static func newCachedTieredDispenseNoticeStore(_ inner: MemoryTieredDispenseNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredDispenseNoticeStore {
        return CachedTieredDispenseNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered dispense notices. Empty fields match all.
    final class TieredDispenseNoticeQuery {
        var source: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredDispenseNotice) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredDispenseNotice]) -> [TieredDispenseNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredDispenseNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredDispenseNotices(_ store: any TieredDispenseNoticeStore, query: TieredDispenseNoticeQuery) -> [TieredDispenseNotice] {
        return query.apply(store.list())
    }
}

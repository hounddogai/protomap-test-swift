import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot notices by code.
    protocol SlotNoticeStore {
        func find(_ code: String) -> SlotNotice?
        func save(_ item: SlotNotice)
        func remove(_ code: String) -> Bool
        func list() -> [SlotNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotNoticeStore: SlotNoticeStore {
        var items: [String: SlotNotice]
        var order: [String]

        init(items: [String: SlotNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotNotice) {
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

        func list() -> [SlotNotice] {
            var out: [SlotNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotNoticeStore() -> any SlotNoticeStore {
        return MemorySlotNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotNoticeStore: SlotNoticeStore {
        var inner: MemorySlotNoticeStore
        var cache: TTLCache<SlotNotice>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotNoticeStore, cache: TTLCache<SlotNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotNotice? {
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

        func save(_ item: SlotNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotNotice] {
            return inner.list()
        }
    }

    static func newCachedSlotNoticeStore(_ inner: MemorySlotNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotNoticeStore {
        return CachedSlotNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot notices. Empty fields match all.
    final class SlotNoticeQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotNotice) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SlotNotice]) -> [SlotNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotNotices(_ store: any SlotNoticeStore, query: SlotNoticeQuery) -> [SlotNotice] {
        return query.apply(store.list())
    }
}

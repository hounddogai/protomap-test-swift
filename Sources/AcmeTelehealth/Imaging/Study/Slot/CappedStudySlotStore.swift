import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps capped study slots by code.
    protocol CappedStudySlotStore {
        func find(_ code: String) -> CappedStudySlot?
        func save(_ item: CappedStudySlot)
        func remove(_ code: String) -> Bool
        func list() -> [CappedStudySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedStudySlotStore: CappedStudySlotStore {
        var items: [String: CappedStudySlot]
        var order: [String]

        init(items: [String: CappedStudySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedStudySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedStudySlot) {
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

        func list() -> [CappedStudySlot] {
            var out: [CappedStudySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedStudySlotStore() -> any CappedStudySlotStore {
        return MemoryCappedStudySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedStudySlotStore: CappedStudySlotStore {
        var inner: MemoryCappedStudySlotStore
        var cache: TTLCache<CappedStudySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedStudySlotStore, cache: TTLCache<CappedStudySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedStudySlot? {
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

        func save(_ item: CappedStudySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedStudySlot] {
            return inner.list()
        }
    }

    static func newCachedCappedStudySlotStore(_ inner: MemoryCappedStudySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedStudySlotStore {
        return CachedCappedStudySlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped study slots. Empty fields match all.
    final class CappedStudySlotQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedStudySlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CappedStudySlot]) -> [CappedStudySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedStudySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedStudySlots(_ store: any CappedStudySlotStore, query: CappedStudySlotQuery) -> [CappedStudySlot] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global specimen slots by code.
    protocol GlobalSpecimenSlotStore {
        func find(_ code: String) -> GlobalSpecimenSlot?
        func save(_ item: GlobalSpecimenSlot)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalSpecimenSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalSpecimenSlotStore: GlobalSpecimenSlotStore {
        var items: [String: GlobalSpecimenSlot]
        var order: [String]

        init(items: [String: GlobalSpecimenSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalSpecimenSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalSpecimenSlot) {
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

        func list() -> [GlobalSpecimenSlot] {
            var out: [GlobalSpecimenSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalSpecimenSlotStore() -> any GlobalSpecimenSlotStore {
        return MemoryGlobalSpecimenSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalSpecimenSlotStore: GlobalSpecimenSlotStore {
        var inner: MemoryGlobalSpecimenSlotStore
        var cache: TTLCache<GlobalSpecimenSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalSpecimenSlotStore, cache: TTLCache<GlobalSpecimenSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalSpecimenSlot? {
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

        func save(_ item: GlobalSpecimenSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalSpecimenSlot] {
            return inner.list()
        }
    }

    static func newCachedGlobalSpecimenSlotStore(_ inner: MemoryGlobalSpecimenSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalSpecimenSlotStore {
        return CachedGlobalSpecimenSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global specimen slots. Empty fields match all.
    final class GlobalSpecimenSlotQuery {
        var title: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRetries: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalSpecimenSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalSpecimenSlot]) -> [GlobalSpecimenSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalSpecimenSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalSpecimenSlots(_ store: any GlobalSpecimenSlotStore, query: GlobalSpecimenSlotQuery) -> [GlobalSpecimenSlot] {
        return query.apply(store.list())
    }
}

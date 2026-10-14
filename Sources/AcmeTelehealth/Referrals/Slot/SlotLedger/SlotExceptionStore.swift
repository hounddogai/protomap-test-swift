import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot exceptions by code.
    protocol SlotExceptionStore {
        func find(_ code: String) -> SlotException?
        func save(_ item: SlotException)
        func remove(_ code: String) -> Bool
        func list() -> [SlotException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotExceptionStore: SlotExceptionStore {
        var items: [String: SlotException]
        var order: [String]

        init(items: [String: SlotException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotException) {
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

        func list() -> [SlotException] {
            var out: [SlotException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotExceptionStore() -> any SlotExceptionStore {
        return MemorySlotExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotExceptionStore: SlotExceptionStore {
        var inner: MemorySlotExceptionStore
        var cache: TTLCache<SlotException>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotExceptionStore, cache: TTLCache<SlotException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotException? {
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

        func save(_ item: SlotException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotException] {
            return inner.list()
        }
    }

    static func newCachedSlotExceptionStore(_ inner: MemorySlotExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotExceptionStore {
        return CachedSlotExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot exceptions. Empty fields match all.
    final class SlotExceptionQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [SlotException]) -> [SlotException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotExceptions(_ store: any SlotExceptionStore, query: SlotExceptionQuery) -> [SlotException] {
        return query.apply(store.list())
    }
}

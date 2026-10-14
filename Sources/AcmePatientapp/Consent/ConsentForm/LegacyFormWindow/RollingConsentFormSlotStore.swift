import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form slots by code.
    protocol RollingConsentFormSlotStore {
        func find(_ code: String) -> RollingConsentFormSlot?
        func save(_ item: RollingConsentFormSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormSlotStore: RollingConsentFormSlotStore {
        var items: [String: RollingConsentFormSlot]
        var order: [String]

        init(items: [String: RollingConsentFormSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormSlot) {
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

        func list() -> [RollingConsentFormSlot] {
            var out: [RollingConsentFormSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormSlotStore() -> any RollingConsentFormSlotStore {
        return MemoryRollingConsentFormSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormSlotStore: RollingConsentFormSlotStore {
        var inner: MemoryRollingConsentFormSlotStore
        var cache: TTLCache<RollingConsentFormSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormSlotStore, cache: TTLCache<RollingConsentFormSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormSlot? {
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

        func save(_ item: RollingConsentFormSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormSlot] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormSlotStore(_ inner: MemoryRollingConsentFormSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormSlotStore {
        return CachedRollingConsentFormSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form slots. Empty fields match all.
    final class RollingConsentFormSlotQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingConsentFormSlot]) -> [RollingConsentFormSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormSlots(_ store: any RollingConsentFormSlotStore, query: RollingConsentFormSlotQuery) -> [RollingConsentFormSlot] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot templates by code.
    protocol SlotTemplateStore {
        func find(_ code: String) -> SlotTemplate?
        func save(_ item: SlotTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [SlotTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotTemplateStore: SlotTemplateStore {
        var items: [String: SlotTemplate]
        var order: [String]

        init(items: [String: SlotTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotTemplate) {
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

        func list() -> [SlotTemplate] {
            var out: [SlotTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotTemplateStore() -> any SlotTemplateStore {
        return MemorySlotTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotTemplateStore: SlotTemplateStore {
        var inner: MemorySlotTemplateStore
        var cache: TTLCache<SlotTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotTemplateStore, cache: TTLCache<SlotTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotTemplate? {
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

        func save(_ item: SlotTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotTemplate] {
            return inner.list()
        }
    }

    static func newCachedSlotTemplateStore(_ inner: MemorySlotTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotTemplateStore {
        return CachedSlotTemplateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot templates. Empty fields match all.
    final class SlotTemplateQuery {
        var unit: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotTemplate) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotTemplate]) -> [SlotTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotTemplates(_ store: any SlotTemplateStore, query: SlotTemplateQuery) -> [SlotTemplate] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual bed board windows by code.
    protocol ManualBedBoardWindowStore {
        func find(_ code: String) -> ManualBedBoardWindow?
        func save(_ item: ManualBedBoardWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ManualBedBoardWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualBedBoardWindowStore: ManualBedBoardWindowStore {
        var items: [String: ManualBedBoardWindow]
        var order: [String]

        init(items: [String: ManualBedBoardWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualBedBoardWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualBedBoardWindow) {
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

        func list() -> [ManualBedBoardWindow] {
            var out: [ManualBedBoardWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualBedBoardWindowStore() -> any ManualBedBoardWindowStore {
        return MemoryManualBedBoardWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualBedBoardWindowStore: ManualBedBoardWindowStore {
        var inner: MemoryManualBedBoardWindowStore
        var cache: TTLCache<ManualBedBoardWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualBedBoardWindowStore, cache: TTLCache<ManualBedBoardWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualBedBoardWindow? {
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

        func save(_ item: ManualBedBoardWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualBedBoardWindow] {
            return inner.list()
        }
    }

    static func newCachedManualBedBoardWindowStore(_ inner: MemoryManualBedBoardWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualBedBoardWindowStore {
        return CachedManualBedBoardWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual bed board windows. Empty fields match all.
    final class ManualBedBoardWindowQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualBedBoardWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ManualBedBoardWindow]) -> [ManualBedBoardWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualBedBoardWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualBedBoardWindows(_ store: any ManualBedBoardWindowStore, query: ManualBedBoardWindowQuery) -> [ManualBedBoardWindow] {
        return query.apply(store.list())
    }
}

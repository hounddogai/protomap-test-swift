import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality windows by code.
    protocol ModalityWindowStore {
        func find(_ code: String) -> ModalityWindow?
        func save(_ item: ModalityWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityWindowStore: ModalityWindowStore {
        var items: [String: ModalityWindow]
        var order: [String]

        init(items: [String: ModalityWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityWindow) {
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

        func list() -> [ModalityWindow] {
            var out: [ModalityWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityWindowStore() -> any ModalityWindowStore {
        return MemoryModalityWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityWindowStore: ModalityWindowStore {
        var inner: MemoryModalityWindowStore
        var cache: TTLCache<ModalityWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityWindowStore, cache: TTLCache<ModalityWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityWindow? {
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

        func save(_ item: ModalityWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityWindow] {
            return inner.list()
        }
    }

    static func newCachedModalityWindowStore(_ inner: MemoryModalityWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityWindowStore {
        return CachedModalityWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality windows. Empty fields match all.
    final class ModalityWindowQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityWindow]) -> [ModalityWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityWindows(_ store: any ModalityWindowStore, query: ModalityWindowQuery) -> [ModalityWindow] {
        return query.apply(store.list())
    }
}

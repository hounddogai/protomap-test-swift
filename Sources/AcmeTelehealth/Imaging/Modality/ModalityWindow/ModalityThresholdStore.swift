import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality thresholds by code.
    protocol ModalityThresholdStore {
        func find(_ code: String) -> ModalityThreshold?
        func save(_ item: ModalityThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityThresholdStore: ModalityThresholdStore {
        var items: [String: ModalityThreshold]
        var order: [String]

        init(items: [String: ModalityThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityThreshold) {
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

        func list() -> [ModalityThreshold] {
            var out: [ModalityThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityThresholdStore() -> any ModalityThresholdStore {
        return MemoryModalityThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityThresholdStore: ModalityThresholdStore {
        var inner: MemoryModalityThresholdStore
        var cache: TTLCache<ModalityThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityThresholdStore, cache: TTLCache<ModalityThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityThreshold? {
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

        func save(_ item: ModalityThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityThreshold] {
            return inner.list()
        }
    }

    static func newCachedModalityThresholdStore(_ inner: MemoryModalityThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityThresholdStore {
        return CachedModalityThresholdStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality thresholds. Empty fields match all.
    final class ModalityThresholdQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ModalityThreshold]) -> [ModalityThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityThresholds(_ store: any ModalityThresholdStore, query: ModalityThresholdQuery) -> [ModalityThreshold] {
        return query.apply(store.list())
    }
}

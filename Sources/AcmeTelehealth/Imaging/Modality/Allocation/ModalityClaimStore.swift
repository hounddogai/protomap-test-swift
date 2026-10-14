import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality claims by code.
    protocol ModalityClaimStore {
        func find(_ code: String) -> ModalityClaim?
        func save(_ item: ModalityClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityClaimStore: ModalityClaimStore {
        var items: [String: ModalityClaim]
        var order: [String]

        init(items: [String: ModalityClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityClaim) {
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

        func list() -> [ModalityClaim] {
            var out: [ModalityClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityClaimStore() -> any ModalityClaimStore {
        return MemoryModalityClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityClaimStore: ModalityClaimStore {
        var inner: MemoryModalityClaimStore
        var cache: TTLCache<ModalityClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityClaimStore, cache: TTLCache<ModalityClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityClaim? {
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

        func save(_ item: ModalityClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityClaim] {
            return inner.list()
        }
    }

    static func newCachedModalityClaimStore(_ inner: MemoryModalityClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityClaimStore {
        return CachedModalityClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality claims. Empty fields match all.
    final class ModalityClaimQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityClaim) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityClaim]) -> [ModalityClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityClaims(_ store: any ModalityClaimStore, query: ModalityClaimQuery) -> [ModalityClaim] {
        return query.apply(store.list())
    }
}

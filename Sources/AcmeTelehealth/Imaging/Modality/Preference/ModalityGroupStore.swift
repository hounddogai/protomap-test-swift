import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality groups by code.
    protocol ModalityGroupStore {
        func find(_ code: String) -> ModalityGroup?
        func save(_ item: ModalityGroup)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityGroupStore: ModalityGroupStore {
        var items: [String: ModalityGroup]
        var order: [String]

        init(items: [String: ModalityGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityGroup) {
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

        func list() -> [ModalityGroup] {
            var out: [ModalityGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityGroupStore() -> any ModalityGroupStore {
        return MemoryModalityGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityGroupStore: ModalityGroupStore {
        var inner: MemoryModalityGroupStore
        var cache: TTLCache<ModalityGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityGroupStore, cache: TTLCache<ModalityGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityGroup? {
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

        func save(_ item: ModalityGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityGroup] {
            return inner.list()
        }
    }

    static func newCachedModalityGroupStore(_ inner: MemoryModalityGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityGroupStore {
        return CachedModalityGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality groups. Empty fields match all.
    final class ModalityGroupQuery {
        var unit: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRevision: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityGroup]) -> [ModalityGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityGroups(_ store: any ModalityGroupStore, query: ModalityGroupQuery) -> [ModalityGroup] {
        return query.apply(store.list())
    }
}

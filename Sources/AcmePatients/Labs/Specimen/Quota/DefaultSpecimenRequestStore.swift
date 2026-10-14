import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default specimen requests by code.
    protocol DefaultSpecimenRequestStore {
        func find(_ code: String) -> DefaultSpecimenRequest?
        func save(_ item: DefaultSpecimenRequest)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSpecimenRequest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSpecimenRequestStore: DefaultSpecimenRequestStore {
        var items: [String: DefaultSpecimenRequest]
        var order: [String]

        init(items: [String: DefaultSpecimenRequest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSpecimenRequest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSpecimenRequest) {
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

        func list() -> [DefaultSpecimenRequest] {
            var out: [DefaultSpecimenRequest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSpecimenRequestStore() -> any DefaultSpecimenRequestStore {
        return MemoryDefaultSpecimenRequestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSpecimenRequestStore: DefaultSpecimenRequestStore {
        var inner: MemoryDefaultSpecimenRequestStore
        var cache: TTLCache<DefaultSpecimenRequest>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSpecimenRequestStore, cache: TTLCache<DefaultSpecimenRequest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSpecimenRequest? {
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

        func save(_ item: DefaultSpecimenRequest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSpecimenRequest] {
            return inner.list()
        }
    }

    static func newCachedDefaultSpecimenRequestStore(_ inner: MemoryDefaultSpecimenRequestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSpecimenRequestStore {
        return CachedDefaultSpecimenRequestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default specimen requests. Empty fields match all.
    final class DefaultSpecimenRequestQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSpecimenRequest) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultSpecimenRequest]) -> [DefaultSpecimenRequest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSpecimenRequest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSpecimenRequests(_ store: any DefaultSpecimenRequestStore, query: DefaultSpecimenRequestQuery) -> [DefaultSpecimenRequest] {
        return query.apply(store.list())
    }
}

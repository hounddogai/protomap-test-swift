import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive program exceptions by code.
    protocol AdaptiveProgramExceptionStore {
        func find(_ code: String) -> AdaptiveProgramException?
        func save(_ item: AdaptiveProgramException)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveProgramException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveProgramExceptionStore: AdaptiveProgramExceptionStore {
        var items: [String: AdaptiveProgramException]
        var order: [String]

        init(items: [String: AdaptiveProgramException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveProgramException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveProgramException) {
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

        func list() -> [AdaptiveProgramException] {
            var out: [AdaptiveProgramException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveProgramExceptionStore() -> any AdaptiveProgramExceptionStore {
        return MemoryAdaptiveProgramExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveProgramExceptionStore: AdaptiveProgramExceptionStore {
        var inner: MemoryAdaptiveProgramExceptionStore
        var cache: TTLCache<AdaptiveProgramException>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveProgramExceptionStore, cache: TTLCache<AdaptiveProgramException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveProgramException? {
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

        func save(_ item: AdaptiveProgramException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveProgramException] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveProgramExceptionStore(_ inner: MemoryAdaptiveProgramExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveProgramExceptionStore {
        return CachedAdaptiveProgramExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive program exceptions. Empty fields match all.
    final class AdaptiveProgramExceptionQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveProgramException) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveProgramException]) -> [AdaptiveProgramException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveProgramException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveProgramExceptions(_ store: any AdaptiveProgramExceptionStore, query: AdaptiveProgramExceptionQuery) -> [AdaptiveProgramException] {
        return query.apply(store.list())
    }
}

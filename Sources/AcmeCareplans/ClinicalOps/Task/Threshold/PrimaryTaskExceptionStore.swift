import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary task exceptions by code.
    protocol PrimaryTaskExceptionStore {
        func find(_ code: String) -> PrimaryTaskException?
        func save(_ item: PrimaryTaskException)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryTaskException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryTaskExceptionStore: PrimaryTaskExceptionStore {
        var items: [String: PrimaryTaskException]
        var order: [String]

        init(items: [String: PrimaryTaskException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryTaskException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryTaskException) {
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

        func list() -> [PrimaryTaskException] {
            var out: [PrimaryTaskException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryTaskExceptionStore() -> any PrimaryTaskExceptionStore {
        return MemoryPrimaryTaskExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryTaskExceptionStore: PrimaryTaskExceptionStore {
        var inner: MemoryPrimaryTaskExceptionStore
        var cache: TTLCache<PrimaryTaskException>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryTaskExceptionStore, cache: TTLCache<PrimaryTaskException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryTaskException? {
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

        func save(_ item: PrimaryTaskException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryTaskException] {
            return inner.list()
        }
    }

    static func newCachedPrimaryTaskExceptionStore(_ inner: MemoryPrimaryTaskExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryTaskExceptionStore {
        return CachedPrimaryTaskExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary task exceptions. Empty fields match all.
    final class PrimaryTaskExceptionQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryTaskException) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryTaskException]) -> [PrimaryTaskException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryTaskException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryTaskExceptions(_ store: any PrimaryTaskExceptionStore, query: PrimaryTaskExceptionQuery) -> [PrimaryTaskException] {
        return query.apply(store.list())
    }
}

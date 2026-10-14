import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program exceptions by code.
    protocol ProgramExceptionStore {
        func find(_ code: String) -> ProgramException?
        func save(_ item: ProgramException)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramExceptionStore: ProgramExceptionStore {
        var items: [String: ProgramException]
        var order: [String]

        init(items: [String: ProgramException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramException) {
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

        func list() -> [ProgramException] {
            var out: [ProgramException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramExceptionStore() -> any ProgramExceptionStore {
        return MemoryProgramExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramExceptionStore: ProgramExceptionStore {
        var inner: MemoryProgramExceptionStore
        var cache: TTLCache<ProgramException>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramExceptionStore, cache: TTLCache<ProgramException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramException? {
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

        func save(_ item: ProgramException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramException] {
            return inner.list()
        }
    }

    static func newCachedProgramExceptionStore(_ inner: MemoryProgramExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramExceptionStore {
        return CachedProgramExceptionStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program exceptions. Empty fields match all.
    final class ProgramExceptionQuery {
        var country: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRetries: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramException) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramException]) -> [ProgramException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramExceptions(_ store: any ProgramExceptionStore, query: ProgramExceptionQuery) -> [ProgramException] {
        return query.apply(store.list())
    }
}

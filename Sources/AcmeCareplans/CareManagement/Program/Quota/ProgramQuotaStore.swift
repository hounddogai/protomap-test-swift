import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps program quotas by code.
    protocol ProgramQuotaStore {
        func find(_ code: String) -> ProgramQuota?
        func save(_ item: ProgramQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ProgramQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProgramQuotaStore: ProgramQuotaStore {
        var items: [String: ProgramQuota]
        var order: [String]

        init(items: [String: ProgramQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProgramQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProgramQuota) {
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

        func list() -> [ProgramQuota] {
            var out: [ProgramQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProgramQuotaStore() -> any ProgramQuotaStore {
        return MemoryProgramQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProgramQuotaStore: ProgramQuotaStore {
        var inner: MemoryProgramQuotaStore
        var cache: TTLCache<ProgramQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryProgramQuotaStore, cache: TTLCache<ProgramQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProgramQuota? {
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

        func save(_ item: ProgramQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProgramQuota] {
            return inner.list()
        }
    }

    static func newCachedProgramQuotaStore(_ inner: MemoryProgramQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProgramQuotaStore {
        return CachedProgramQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects program quotas. Empty fields match all.
    final class ProgramQuotaQuery {
        var locale: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProgramQuota) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProgramQuota]) -> [ProgramQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProgramQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProgramQuotas(_ store: any ProgramQuotaStore, query: ProgramQuotaQuery) -> [ProgramQuota] {
        return query.apply(store.list())
    }
}

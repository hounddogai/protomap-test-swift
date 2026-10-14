import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality quotas by code.
    protocol ModalityQuotaStore {
        func find(_ code: String) -> ModalityQuota?
        func save(_ item: ModalityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityQuotaStore: ModalityQuotaStore {
        var items: [String: ModalityQuota]
        var order: [String]

        init(items: [String: ModalityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityQuota) {
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

        func list() -> [ModalityQuota] {
            var out: [ModalityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityQuotaStore() -> any ModalityQuotaStore {
        return MemoryModalityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityQuotaStore: ModalityQuotaStore {
        var inner: MemoryModalityQuotaStore
        var cache: TTLCache<ModalityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityQuotaStore, cache: TTLCache<ModalityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityQuota? {
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

        func save(_ item: ModalityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityQuota] {
            return inner.list()
        }
    }

    static func newCachedModalityQuotaStore(_ inner: MemoryModalityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityQuotaStore {
        return CachedModalityQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality quotas. Empty fields match all.
    final class ModalityQuotaQuery {
        var ward: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVersion: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityQuota) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityQuota]) -> [ModalityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityQuotas(_ store: any ModalityQuotaStore, query: ModalityQuotaQuery) -> [ModalityQuota] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback program notices by code.
    protocol FallbackProgramNoticeStore {
        func find(_ code: String) -> FallbackProgramNotice?
        func save(_ item: FallbackProgramNotice)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackProgramNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackProgramNoticeStore: FallbackProgramNoticeStore {
        var items: [String: FallbackProgramNotice]
        var order: [String]

        init(items: [String: FallbackProgramNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackProgramNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackProgramNotice) {
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

        func list() -> [FallbackProgramNotice] {
            var out: [FallbackProgramNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackProgramNoticeStore() -> any FallbackProgramNoticeStore {
        return MemoryFallbackProgramNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackProgramNoticeStore: FallbackProgramNoticeStore {
        var inner: MemoryFallbackProgramNoticeStore
        var cache: TTLCache<FallbackProgramNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackProgramNoticeStore, cache: TTLCache<FallbackProgramNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackProgramNotice? {
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

        func save(_ item: FallbackProgramNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackProgramNotice] {
            return inner.list()
        }
    }

    static func newCachedFallbackProgramNoticeStore(_ inner: MemoryFallbackProgramNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackProgramNoticeStore {
        return CachedFallbackProgramNoticeStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback program notices. Empty fields match all.
    final class FallbackProgramNoticeQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackProgramNotice) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [FallbackProgramNotice]) -> [FallbackProgramNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackProgramNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackProgramNotices(_ store: any FallbackProgramNoticeStore, query: FallbackProgramNoticeQuery) -> [FallbackProgramNotice] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Keeps capped disclosure records by code.
    protocol CappedDisclosureRecordStore {
        func find(_ code: String) -> CappedDisclosureRecord?
        func save(_ item: CappedDisclosureRecord)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDisclosureRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDisclosureRecordStore: CappedDisclosureRecordStore {
        var items: [String: CappedDisclosureRecord]
        var order: [String]

        init(items: [String: CappedDisclosureRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDisclosureRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDisclosureRecord) {
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

        func list() -> [CappedDisclosureRecord] {
            var out: [CappedDisclosureRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDisclosureRecordStore() -> any CappedDisclosureRecordStore {
        return MemoryCappedDisclosureRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDisclosureRecordStore: CappedDisclosureRecordStore {
        var inner: MemoryCappedDisclosureRecordStore
        var cache: TTLCache<CappedDisclosureRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDisclosureRecordStore, cache: TTLCache<CappedDisclosureRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDisclosureRecord? {
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

        func save(_ item: CappedDisclosureRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDisclosureRecord] {
            return inner.list()
        }
    }

    static func newCachedCappedDisclosureRecordStore(_ inner: MemoryCappedDisclosureRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDisclosureRecordStore {
        return CachedCappedDisclosureRecordStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped disclosure records. Empty fields match all.
    final class CappedDisclosureRecordQuery {
        var region: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDisclosureRecord) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDisclosureRecord]) -> [CappedDisclosureRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDisclosureRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDisclosureRecords(_ store: any CappedDisclosureRecordStore, query: CappedDisclosureRecordQuery) -> [CappedDisclosureRecord] {
        return query.apply(store.list())
    }
}

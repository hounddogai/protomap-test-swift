import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol entries by code.
    protocol CareProtocolEntryStore {
        func find(_ code: String) -> CareProtocolEntry?
        func save(_ item: CareProtocolEntry)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolEntryStore: CareProtocolEntryStore {
        var items: [String: CareProtocolEntry]
        var order: [String]

        init(items: [String: CareProtocolEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolEntry) {
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

        func list() -> [CareProtocolEntry] {
            var out: [CareProtocolEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolEntryStore() -> any CareProtocolEntryStore {
        return MemoryCareProtocolEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolEntryStore: CareProtocolEntryStore {
        var inner: MemoryCareProtocolEntryStore
        var cache: TTLCache<CareProtocolEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolEntryStore, cache: TTLCache<CareProtocolEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolEntry? {
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

        func save(_ item: CareProtocolEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolEntry] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolEntryStore(_ inner: MemoryCareProtocolEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolEntryStore {
        return CachedCareProtocolEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol entries. Empty fields match all.
    final class CareProtocolEntryQuery {
        var segment: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolEntry) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolEntry]) -> [CareProtocolEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolEntries(_ store: any CareProtocolEntryStore, query: CareProtocolEntryQuery) -> [CareProtocolEntry] {
        return query.apply(store.list())
    }
}

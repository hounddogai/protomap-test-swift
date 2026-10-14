import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps tiered risk score entries by code.
    protocol TieredRiskScoreEntryStore {
        func find(_ code: String) -> TieredRiskScoreEntry?
        func save(_ item: TieredRiskScoreEntry)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRiskScoreEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRiskScoreEntryStore: TieredRiskScoreEntryStore {
        var items: [String: TieredRiskScoreEntry]
        var order: [String]

        init(items: [String: TieredRiskScoreEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRiskScoreEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRiskScoreEntry) {
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

        func list() -> [TieredRiskScoreEntry] {
            var out: [TieredRiskScoreEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRiskScoreEntryStore() -> any TieredRiskScoreEntryStore {
        return MemoryTieredRiskScoreEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRiskScoreEntryStore: TieredRiskScoreEntryStore {
        var inner: MemoryTieredRiskScoreEntryStore
        var cache: TTLCache<TieredRiskScoreEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRiskScoreEntryStore, cache: TTLCache<TieredRiskScoreEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRiskScoreEntry? {
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

        func save(_ item: TieredRiskScoreEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRiskScoreEntry] {
            return inner.list()
        }
    }

    static func newCachedTieredRiskScoreEntryStore(_ inner: MemoryTieredRiskScoreEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRiskScoreEntryStore {
        return CachedTieredRiskScoreEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered risk score entries. Empty fields match all.
    final class TieredRiskScoreEntryQuery {
        var country: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRevision: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRiskScoreEntry) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [TieredRiskScoreEntry]) -> [TieredRiskScoreEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRiskScoreEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRiskScoreEntries(_ store: any TieredRiskScoreEntryStore, query: TieredRiskScoreEntryQuery) -> [TieredRiskScoreEntry] {
        return query.apply(store.list())
    }
}

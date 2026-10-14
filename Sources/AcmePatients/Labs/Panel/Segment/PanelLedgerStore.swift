import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel ledgers by code.
    protocol PanelLedgerStore {
        func find(_ code: String) -> PanelLedger?
        func save(_ item: PanelLedger)
        func remove(_ code: String) -> Bool
        func list() -> [PanelLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelLedgerStore: PanelLedgerStore {
        var items: [String: PanelLedger]
        var order: [String]

        init(items: [String: PanelLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelLedger) {
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

        func list() -> [PanelLedger] {
            var out: [PanelLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelLedgerStore() -> any PanelLedgerStore {
        return MemoryPanelLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelLedgerStore: PanelLedgerStore {
        var inner: MemoryPanelLedgerStore
        var cache: TTLCache<PanelLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelLedgerStore, cache: TTLCache<PanelLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelLedger? {
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

        func save(_ item: PanelLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelLedger] {
            return inner.list()
        }
    }

    static func newCachedPanelLedgerStore(_ inner: MemoryPanelLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelLedgerStore {
        return CachedPanelLedgerStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel ledgers. Empty fields match all.
    final class PanelLedgerQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PanelLedger]) -> [PanelLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelLedgers(_ store: any PanelLedgerStore, query: PanelLedgerQuery) -> [PanelLedger] {
        return query.apply(store.list())
    }
}

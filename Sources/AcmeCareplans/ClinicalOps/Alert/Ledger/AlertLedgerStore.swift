import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert ledgers by code.
    protocol AlertLedgerStore {
        func find(_ code: String) -> AlertLedger?
        func save(_ item: AlertLedger)
        func remove(_ code: String) -> Bool
        func list() -> [AlertLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertLedgerStore: AlertLedgerStore {
        var items: [String: AlertLedger]
        var order: [String]

        init(items: [String: AlertLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertLedger) {
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

        func list() -> [AlertLedger] {
            var out: [AlertLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertLedgerStore() -> any AlertLedgerStore {
        return MemoryAlertLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertLedgerStore: AlertLedgerStore {
        var inner: MemoryAlertLedgerStore
        var cache: TTLCache<AlertLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertLedgerStore, cache: TTLCache<AlertLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertLedger? {
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

        func save(_ item: AlertLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertLedger] {
            return inner.list()
        }
    }

    static func newCachedAlertLedgerStore(_ inner: MemoryAlertLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertLedgerStore {
        return CachedAlertLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert ledgers. Empty fields match all.
    final class AlertLedgerQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertLedger) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AlertLedger]) -> [AlertLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertLedgers(_ store: any AlertLedgerStore, query: AlertLedgerQuery) -> [AlertLedger] {
        return query.apply(store.list())
    }
}

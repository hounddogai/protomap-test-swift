import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality ledgers by code.
    protocol ModalityLedgerStore {
        func find(_ code: String) -> ModalityLedger?
        func save(_ item: ModalityLedger)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityLedgerStore: ModalityLedgerStore {
        var items: [String: ModalityLedger]
        var order: [String]

        init(items: [String: ModalityLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityLedger) {
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

        func list() -> [ModalityLedger] {
            var out: [ModalityLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityLedgerStore() -> any ModalityLedgerStore {
        return MemoryModalityLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityLedgerStore: ModalityLedgerStore {
        var inner: MemoryModalityLedgerStore
        var cache: TTLCache<ModalityLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityLedgerStore, cache: TTLCache<ModalityLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityLedger? {
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

        func save(_ item: ModalityLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityLedger] {
            return inner.list()
        }
    }

    static func newCachedModalityLedgerStore(_ inner: MemoryModalityLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityLedgerStore {
        return CachedModalityLedgerStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality ledgers. Empty fields match all.
    final class ModalityLedgerQuery {
        var channel: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityLedger) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityLedger]) -> [ModalityLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityLedgers(_ store: any ModalityLedgerStore, query: ModalityLedgerQuery) -> [ModalityLedger] {
        return query.apply(store.list())
    }
}

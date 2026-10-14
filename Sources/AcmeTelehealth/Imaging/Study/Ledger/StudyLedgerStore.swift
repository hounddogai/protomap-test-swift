import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study ledgers by code.
    protocol StudyLedgerStore {
        func find(_ code: String) -> StudyLedger?
        func save(_ item: StudyLedger)
        func remove(_ code: String) -> Bool
        func list() -> [StudyLedger]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyLedgerStore: StudyLedgerStore {
        var items: [String: StudyLedger]
        var order: [String]

        init(items: [String: StudyLedger], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyLedger? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyLedger) {
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

        func list() -> [StudyLedger] {
            var out: [StudyLedger] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyLedgerStore() -> any StudyLedgerStore {
        return MemoryStudyLedgerStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyLedgerStore: StudyLedgerStore {
        var inner: MemoryStudyLedgerStore
        var cache: TTLCache<StudyLedger>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyLedgerStore, cache: TTLCache<StudyLedger>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyLedger? {
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

        func save(_ item: StudyLedger) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyLedger] {
            return inner.list()
        }
    }

    static func newCachedStudyLedgerStore(_ inner: MemoryStudyLedgerStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyLedgerStore {
        return CachedStudyLedgerStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study ledgers. Empty fields match all.
    final class StudyLedgerQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyLedger) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyLedger]) -> [StudyLedger] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyLedger) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyLedgers(_ store: any StudyLedgerStore, query: StudyLedgerQuery) -> [StudyLedger] {
        return query.apply(store.list())
    }
}

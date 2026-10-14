import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality records by code.
    protocol ModalityRecordStore {
        func find(_ code: String) -> ModalityRecord?
        func save(_ item: ModalityRecord)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityRecord]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityRecordStore: ModalityRecordStore {
        var items: [String: ModalityRecord]
        var order: [String]

        init(items: [String: ModalityRecord], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityRecord? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityRecord) {
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

        func list() -> [ModalityRecord] {
            var out: [ModalityRecord] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityRecordStore() -> any ModalityRecordStore {
        return MemoryModalityRecordStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityRecordStore: ModalityRecordStore {
        var inner: MemoryModalityRecordStore
        var cache: TTLCache<ModalityRecord>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityRecordStore, cache: TTLCache<ModalityRecord>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityRecord? {
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

        func save(_ item: ModalityRecord) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityRecord] {
            return inner.list()
        }
    }

    static func newCachedModalityRecordStore(_ inner: MemoryModalityRecordStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityRecordStore {
        return CachedModalityRecordStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality records. Empty fields match all.
    final class ModalityRecordQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityRecord) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityRecord]) -> [ModalityRecord] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityRecord) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityRecords(_ store: any ModalityRecordStore, query: ModalityRecordQuery) -> [ModalityRecord] {
        return query.apply(store.list())
    }
}

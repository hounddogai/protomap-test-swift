import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board agreements by code.
    protocol BedBoardAgreementStore {
        func find(_ code: String) -> BedBoardAgreement?
        func save(_ item: BedBoardAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardAgreementStore: BedBoardAgreementStore {
        var items: [String: BedBoardAgreement]
        var order: [String]

        init(items: [String: BedBoardAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardAgreement) {
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

        func list() -> [BedBoardAgreement] {
            var out: [BedBoardAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardAgreementStore() -> any BedBoardAgreementStore {
        return MemoryBedBoardAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardAgreementStore: BedBoardAgreementStore {
        var inner: MemoryBedBoardAgreementStore
        var cache: TTLCache<BedBoardAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardAgreementStore, cache: TTLCache<BedBoardAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardAgreement? {
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

        func save(_ item: BedBoardAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardAgreement] {
            return inner.list()
        }
    }

    static func newCachedBedBoardAgreementStore(_ inner: MemoryBedBoardAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardAgreementStore {
        return CachedBedBoardAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board agreements. Empty fields match all.
    final class BedBoardAgreementQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardAgreement) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardAgreement]) -> [BedBoardAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardAgreements(_ store: any BedBoardAgreementStore, query: BedBoardAgreementQuery) -> [BedBoardAgreement] {
        return query.apply(store.list())
    }
}

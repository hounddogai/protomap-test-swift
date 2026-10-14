import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board policies by code.
    protocol BedBoardPolicyStore {
        func find(_ code: String) -> BedBoardPolicy?
        func save(_ item: BedBoardPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardPolicyStore: BedBoardPolicyStore {
        var items: [String: BedBoardPolicy]
        var order: [String]

        init(items: [String: BedBoardPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardPolicy) {
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

        func list() -> [BedBoardPolicy] {
            var out: [BedBoardPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardPolicyStore() -> any BedBoardPolicyStore {
        return MemoryBedBoardPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardPolicyStore: BedBoardPolicyStore {
        var inner: MemoryBedBoardPolicyStore
        var cache: TTLCache<BedBoardPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardPolicyStore, cache: TTLCache<BedBoardPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardPolicy? {
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

        func save(_ item: BedBoardPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardPolicy] {
            return inner.list()
        }
    }

    static func newCachedBedBoardPolicyStore(_ inner: MemoryBedBoardPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardPolicyStore {
        return CachedBedBoardPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board policies. Empty fields match all.
    final class BedBoardPolicyQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [BedBoardPolicy]) -> [BedBoardPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardPolicies(_ store: any BedBoardPolicyStore, query: BedBoardPolicyQuery) -> [BedBoardPolicy] {
        return query.apply(store.list())
    }
}

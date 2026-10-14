import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional eligibility notices by code.
    protocol RegionalEligibilityNoticeStore {
        func find(_ code: String) -> RegionalEligibilityNotice?
        func save(_ item: RegionalEligibilityNotice)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalEligibilityNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalEligibilityNoticeStore: RegionalEligibilityNoticeStore {
        var items: [String: RegionalEligibilityNotice]
        var order: [String]

        init(items: [String: RegionalEligibilityNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalEligibilityNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalEligibilityNotice) {
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

        func list() -> [RegionalEligibilityNotice] {
            var out: [RegionalEligibilityNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalEligibilityNoticeStore() -> any RegionalEligibilityNoticeStore {
        return MemoryRegionalEligibilityNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalEligibilityNoticeStore: RegionalEligibilityNoticeStore {
        var inner: MemoryRegionalEligibilityNoticeStore
        var cache: TTLCache<RegionalEligibilityNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalEligibilityNoticeStore, cache: TTLCache<RegionalEligibilityNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalEligibilityNotice? {
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

        func save(_ item: RegionalEligibilityNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalEligibilityNotice] {
            return inner.list()
        }
    }

    static func newCachedRegionalEligibilityNoticeStore(_ inner: MemoryRegionalEligibilityNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalEligibilityNoticeStore {
        return CachedRegionalEligibilityNoticeStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional eligibility notices. Empty fields match all.
    final class RegionalEligibilityNoticeQuery {
        var unit: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalEligibilityNotice) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RegionalEligibilityNotice]) -> [RegionalEligibilityNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalEligibilityNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalEligibilityNotices(_ store: any RegionalEligibilityNoticeStore, query: RegionalEligibilityNoticeQuery) -> [RegionalEligibilityNotice] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps legacy alert notices by code.
    protocol LegacyAlertNoticeStore {
        func find(_ code: String) -> LegacyAlertNotice?
        func save(_ item: LegacyAlertNotice)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAlertNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAlertNoticeStore: LegacyAlertNoticeStore {
        var items: [String: LegacyAlertNotice]
        var order: [String]

        init(items: [String: LegacyAlertNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAlertNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAlertNotice) {
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

        func list() -> [LegacyAlertNotice] {
            var out: [LegacyAlertNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAlertNoticeStore() -> any LegacyAlertNoticeStore {
        return MemoryLegacyAlertNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAlertNoticeStore: LegacyAlertNoticeStore {
        var inner: MemoryLegacyAlertNoticeStore
        var cache: TTLCache<LegacyAlertNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAlertNoticeStore, cache: TTLCache<LegacyAlertNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAlertNotice? {
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

        func save(_ item: LegacyAlertNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAlertNotice] {
            return inner.list()
        }
    }

    static func newCachedLegacyAlertNoticeStore(_ inner: MemoryLegacyAlertNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAlertNoticeStore {
        return CachedLegacyAlertNoticeStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy alert notices. Empty fields match all.
    final class LegacyAlertNoticeQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAlertNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [LegacyAlertNotice]) -> [LegacyAlertNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAlertNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAlertNotices(_ store: any LegacyAlertNoticeStore, query: LegacyAlertNoticeQuery) -> [LegacyAlertNotice] {
        return query.apply(store.list())
    }
}

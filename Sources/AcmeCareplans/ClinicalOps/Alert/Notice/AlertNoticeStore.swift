import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert notices by code.
    protocol AlertNoticeStore {
        func find(_ code: String) -> AlertNotice?
        func save(_ item: AlertNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AlertNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertNoticeStore: AlertNoticeStore {
        var items: [String: AlertNotice]
        var order: [String]

        init(items: [String: AlertNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertNotice) {
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

        func list() -> [AlertNotice] {
            var out: [AlertNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertNoticeStore() -> any AlertNoticeStore {
        return MemoryAlertNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertNoticeStore: AlertNoticeStore {
        var inner: MemoryAlertNoticeStore
        var cache: TTLCache<AlertNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertNoticeStore, cache: TTLCache<AlertNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertNotice? {
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

        func save(_ item: AlertNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertNotice] {
            return inner.list()
        }
    }

    static func newCachedAlertNoticeStore(_ inner: MemoryAlertNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertNoticeStore {
        return CachedAlertNoticeStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert notices. Empty fields match all.
    final class AlertNoticeQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertNotice) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [AlertNotice]) -> [AlertNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertNotices(_ store: any AlertNoticeStore, query: AlertNoticeQuery) -> [AlertNotice] {
        return query.apply(store.list())
    }
}

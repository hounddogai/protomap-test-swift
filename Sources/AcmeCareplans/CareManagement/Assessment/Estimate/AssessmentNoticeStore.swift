import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment notices by code.
    protocol AssessmentNoticeStore {
        func find(_ code: String) -> AssessmentNotice?
        func save(_ item: AssessmentNotice)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentNotice]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentNoticeStore: AssessmentNoticeStore {
        var items: [String: AssessmentNotice]
        var order: [String]

        init(items: [String: AssessmentNotice], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentNotice? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentNotice) {
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

        func list() -> [AssessmentNotice] {
            var out: [AssessmentNotice] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentNoticeStore() -> any AssessmentNoticeStore {
        return MemoryAssessmentNoticeStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentNoticeStore: AssessmentNoticeStore {
        var inner: MemoryAssessmentNoticeStore
        var cache: TTLCache<AssessmentNotice>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentNoticeStore, cache: TTLCache<AssessmentNotice>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentNotice? {
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

        func save(_ item: AssessmentNotice) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentNotice] {
            return inner.list()
        }
    }

    static func newCachedAssessmentNoticeStore(_ inner: MemoryAssessmentNoticeStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentNoticeStore {
        return CachedAssessmentNoticeStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment notices. Empty fields match all.
    final class AssessmentNoticeQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentNotice) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentNotice]) -> [AssessmentNotice] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentNotice) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentNotices(_ store: any AssessmentNoticeStore, query: AssessmentNoticeQuery) -> [AssessmentNotice] {
        return query.apply(store.list())
    }
}

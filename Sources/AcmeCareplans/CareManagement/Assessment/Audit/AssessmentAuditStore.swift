import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps assessment audits by code.
    protocol AssessmentAuditStore {
        func find(_ code: String) -> AssessmentAudit?
        func save(_ item: AssessmentAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AssessmentAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAssessmentAuditStore: AssessmentAuditStore {
        var items: [String: AssessmentAudit]
        var order: [String]

        init(items: [String: AssessmentAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AssessmentAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AssessmentAudit) {
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

        func list() -> [AssessmentAudit] {
            var out: [AssessmentAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAssessmentAuditStore() -> any AssessmentAuditStore {
        return MemoryAssessmentAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAssessmentAuditStore: AssessmentAuditStore {
        var inner: MemoryAssessmentAuditStore
        var cache: TTLCache<AssessmentAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAssessmentAuditStore, cache: TTLCache<AssessmentAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AssessmentAudit? {
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

        func save(_ item: AssessmentAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AssessmentAudit] {
            return inner.list()
        }
    }

    static func newCachedAssessmentAuditStore(_ inner: MemoryAssessmentAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AssessmentAuditStore {
        return CachedAssessmentAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects assessment audits. Empty fields match all.
    final class AssessmentAuditQuery {
        var source: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AssessmentAudit) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AssessmentAudit]) -> [AssessmentAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AssessmentAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAssessmentAudits(_ store: any AssessmentAuditStore, query: AssessmentAuditQuery) -> [AssessmentAudit] {
        return query.apply(store.list())
    }
}

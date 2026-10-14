import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan drafts by code.
    protocol AcuityPlanDraftStore {
        func find(_ code: String) -> AcuityPlanDraft?
        func save(_ item: AcuityPlanDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanDraftStore: AcuityPlanDraftStore {
        var items: [String: AcuityPlanDraft]
        var order: [String]

        init(items: [String: AcuityPlanDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanDraft) {
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

        func list() -> [AcuityPlanDraft] {
            var out: [AcuityPlanDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanDraftStore() -> any AcuityPlanDraftStore {
        return MemoryAcuityPlanDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanDraftStore: AcuityPlanDraftStore {
        var inner: MemoryAcuityPlanDraftStore
        var cache: TTLCache<AcuityPlanDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanDraftStore, cache: TTLCache<AcuityPlanDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanDraft? {
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

        func save(_ item: AcuityPlanDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanDraft] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanDraftStore(_ inner: MemoryAcuityPlanDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanDraftStore {
        return CachedAcuityPlanDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan drafts. Empty fields match all.
    final class AcuityPlanDraftQuery {
        var label: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AcuityPlanDraft]) -> [AcuityPlanDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanDrafts(_ store: any AcuityPlanDraftStore, query: AcuityPlanDraftQuery) -> [AcuityPlanDraft] {
        return query.apply(store.list())
    }
}

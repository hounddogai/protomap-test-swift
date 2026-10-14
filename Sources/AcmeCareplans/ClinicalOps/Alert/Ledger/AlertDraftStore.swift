import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert drafts by code.
    protocol AlertDraftStore {
        func find(_ code: String) -> AlertDraft?
        func save(_ item: AlertDraft)
        func remove(_ code: String) -> Bool
        func list() -> [AlertDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertDraftStore: AlertDraftStore {
        var items: [String: AlertDraft]
        var order: [String]

        init(items: [String: AlertDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertDraft) {
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

        func list() -> [AlertDraft] {
            var out: [AlertDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertDraftStore() -> any AlertDraftStore {
        return MemoryAlertDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertDraftStore: AlertDraftStore {
        var inner: MemoryAlertDraftStore
        var cache: TTLCache<AlertDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertDraftStore, cache: TTLCache<AlertDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertDraft? {
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

        func save(_ item: AlertDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertDraft] {
            return inner.list()
        }
    }

    static func newCachedAlertDraftStore(_ inner: MemoryAlertDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertDraftStore {
        return CachedAlertDraftStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert drafts. Empty fields match all.
    final class AlertDraftQuery {
        var segment: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertDraft) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [AlertDraft]) -> [AlertDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertDrafts(_ store: any AlertDraftStore, query: AlertDraftQuery) -> [AlertDraft] {
        return query.apply(store.list())
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps pending transfer drafts by code.
    protocol PendingTransferDraftStore {
        func find(_ code: String) -> PendingTransferDraft?
        func save(_ item: PendingTransferDraft)
        func remove(_ code: String) -> Bool
        func list() -> [PendingTransferDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingTransferDraftStore: PendingTransferDraftStore {
        var items: [String: PendingTransferDraft]
        var order: [String]

        init(items: [String: PendingTransferDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingTransferDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingTransferDraft) {
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

        func list() -> [PendingTransferDraft] {
            var out: [PendingTransferDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingTransferDraftStore() -> any PendingTransferDraftStore {
        return MemoryPendingTransferDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingTransferDraftStore: PendingTransferDraftStore {
        var inner: MemoryPendingTransferDraftStore
        var cache: TTLCache<PendingTransferDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingTransferDraftStore, cache: TTLCache<PendingTransferDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingTransferDraft? {
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

        func save(_ item: PendingTransferDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingTransferDraft] {
            return inner.list()
        }
    }

    static func newCachedPendingTransferDraftStore(_ inner: MemoryPendingTransferDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingTransferDraftStore {
        return CachedPendingTransferDraftStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending transfer drafts. Empty fields match all.
    final class PendingTransferDraftQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingTransferDraft) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingTransferDraft]) -> [PendingTransferDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingTransferDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingTransferDrafts(_ store: any PendingTransferDraftStore, query: PendingTransferDraftQuery) -> [PendingTransferDraft] {
        return query.apply(store.list())
    }
}

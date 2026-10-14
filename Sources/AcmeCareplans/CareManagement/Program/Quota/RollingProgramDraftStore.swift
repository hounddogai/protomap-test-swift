import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling program drafts by code.
    protocol RollingProgramDraftStore {
        func find(_ code: String) -> RollingProgramDraft?
        func save(_ item: RollingProgramDraft)
        func remove(_ code: String) -> Bool
        func list() -> [RollingProgramDraft]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingProgramDraftStore: RollingProgramDraftStore {
        var items: [String: RollingProgramDraft]
        var order: [String]

        init(items: [String: RollingProgramDraft], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingProgramDraft? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingProgramDraft) {
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

        func list() -> [RollingProgramDraft] {
            var out: [RollingProgramDraft] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingProgramDraftStore() -> any RollingProgramDraftStore {
        return MemoryRollingProgramDraftStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingProgramDraftStore: RollingProgramDraftStore {
        var inner: MemoryRollingProgramDraftStore
        var cache: TTLCache<RollingProgramDraft>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingProgramDraftStore, cache: TTLCache<RollingProgramDraft>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingProgramDraft? {
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

        func save(_ item: RollingProgramDraft) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingProgramDraft] {
            return inner.list()
        }
    }

    static func newCachedRollingProgramDraftStore(_ inner: MemoryRollingProgramDraftStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingProgramDraftStore {
        return CachedRollingProgramDraftStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling program drafts. Empty fields match all.
    final class RollingProgramDraftQuery {
        var channel: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCopay: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingProgramDraft) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingProgramDraft]) -> [RollingProgramDraft] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingProgramDraft) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingProgramDrafts(_ store: any RollingProgramDraftStore, query: RollingProgramDraftQuery) -> [RollingProgramDraft] {
        return query.apply(store.list())
    }
}

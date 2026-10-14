import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual credential windows by code.
    protocol ManualCredentialWindowStore {
        func find(_ code: String) -> ManualCredentialWindow?
        func save(_ item: ManualCredentialWindow)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCredentialWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCredentialWindowStore: ManualCredentialWindowStore {
        var items: [String: ManualCredentialWindow]
        var order: [String]

        init(items: [String: ManualCredentialWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCredentialWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCredentialWindow) {
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

        func list() -> [ManualCredentialWindow] {
            var out: [ManualCredentialWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCredentialWindowStore() -> any ManualCredentialWindowStore {
        return MemoryManualCredentialWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCredentialWindowStore: ManualCredentialWindowStore {
        var inner: MemoryManualCredentialWindowStore
        var cache: TTLCache<ManualCredentialWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCredentialWindowStore, cache: TTLCache<ManualCredentialWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCredentialWindow? {
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

        func save(_ item: ManualCredentialWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCredentialWindow] {
            return inner.list()
        }
    }

    static func newCachedManualCredentialWindowStore(_ inner: MemoryManualCredentialWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCredentialWindowStore {
        return CachedManualCredentialWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual credential windows. Empty fields match all.
    final class ManualCredentialWindowQuery {
        var category: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCredentialWindow) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ManualCredentialWindow]) -> [ManualCredentialWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCredentialWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCredentialWindows(_ store: any ManualCredentialWindowStore, query: ManualCredentialWindowQuery) -> [ManualCredentialWindow] {
        return query.apply(store.list())
    }
}

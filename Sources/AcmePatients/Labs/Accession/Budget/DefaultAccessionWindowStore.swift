import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default accession windows by code.
    protocol DefaultAccessionWindowStore {
        func find(_ code: String) -> DefaultAccessionWindow?
        func save(_ item: DefaultAccessionWindow)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAccessionWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAccessionWindowStore: DefaultAccessionWindowStore {
        var items: [String: DefaultAccessionWindow]
        var order: [String]

        init(items: [String: DefaultAccessionWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAccessionWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAccessionWindow) {
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

        func list() -> [DefaultAccessionWindow] {
            var out: [DefaultAccessionWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAccessionWindowStore() -> any DefaultAccessionWindowStore {
        return MemoryDefaultAccessionWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAccessionWindowStore: DefaultAccessionWindowStore {
        var inner: MemoryDefaultAccessionWindowStore
        var cache: TTLCache<DefaultAccessionWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAccessionWindowStore, cache: TTLCache<DefaultAccessionWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAccessionWindow? {
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

        func save(_ item: DefaultAccessionWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAccessionWindow] {
            return inner.list()
        }
    }

    static func newCachedDefaultAccessionWindowStore(_ inner: MemoryDefaultAccessionWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAccessionWindowStore {
        return CachedDefaultAccessionWindowStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default accession windows. Empty fields match all.
    final class DefaultAccessionWindowQuery {
        var label: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMargin: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAccessionWindow) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAccessionWindow]) -> [DefaultAccessionWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAccessionWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAccessionWindows(_ store: any DefaultAccessionWindowStore, query: DefaultAccessionWindowQuery) -> [DefaultAccessionWindow] {
        return query.apply(store.list())
    }
}

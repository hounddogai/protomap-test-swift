import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel exceptions by code.
    protocol PanelExceptionStore {
        func find(_ code: String) -> PanelException?
        func save(_ item: PanelException)
        func remove(_ code: String) -> Bool
        func list() -> [PanelException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelExceptionStore: PanelExceptionStore {
        var items: [String: PanelException]
        var order: [String]

        init(items: [String: PanelException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelException) {
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

        func list() -> [PanelException] {
            var out: [PanelException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelExceptionStore() -> any PanelExceptionStore {
        return MemoryPanelExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelExceptionStore: PanelExceptionStore {
        var inner: MemoryPanelExceptionStore
        var cache: TTLCache<PanelException>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelExceptionStore, cache: TTLCache<PanelException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelException? {
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

        func save(_ item: PanelException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelException] {
            return inner.list()
        }
    }

    static func newCachedPanelExceptionStore(_ inner: MemoryPanelExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelExceptionStore {
        return CachedPanelExceptionStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel exceptions. Empty fields match all.
    final class PanelExceptionQuery {
        var locale: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelException) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [PanelException]) -> [PanelException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelExceptions(_ store: any PanelExceptionStore, query: PanelExceptionQuery) -> [PanelException] {
        return query.apply(store.list())
    }
}

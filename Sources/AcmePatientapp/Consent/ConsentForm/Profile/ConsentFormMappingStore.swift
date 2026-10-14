import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form mappings by code.
    protocol ConsentFormMappingStore {
        func find(_ code: String) -> ConsentFormMapping?
        func save(_ item: ConsentFormMapping)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormMappingStore: ConsentFormMappingStore {
        var items: [String: ConsentFormMapping]
        var order: [String]

        init(items: [String: ConsentFormMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormMapping) {
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

        func list() -> [ConsentFormMapping] {
            var out: [ConsentFormMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormMappingStore() -> any ConsentFormMappingStore {
        return MemoryConsentFormMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormMappingStore: ConsentFormMappingStore {
        var inner: MemoryConsentFormMappingStore
        var cache: TTLCache<ConsentFormMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormMappingStore, cache: TTLCache<ConsentFormMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormMapping? {
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

        func save(_ item: ConsentFormMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormMapping] {
            return inner.list()
        }
    }

    static func newCachedConsentFormMappingStore(_ inner: MemoryConsentFormMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormMappingStore {
        return CachedConsentFormMappingStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form mappings. Empty fields match all.
    final class ConsentFormMappingQuery {
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

        func matches(_ item: ConsentFormMapping) -> Bool {
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

        func apply(_ items: [ConsentFormMapping]) -> [ConsentFormMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormMappings(_ store: any ConsentFormMappingStore, query: ConsentFormMappingQuery) -> [ConsentFormMapping] {
        return query.apply(store.list())
    }
}

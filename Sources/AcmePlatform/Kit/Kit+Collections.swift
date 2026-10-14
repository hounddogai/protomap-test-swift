import Foundation

extension Kit.Collections {
    /// Returns the items keep accepts, in order.
    public static func filter<T>(_ items: [T], keep: (T) -> Bool) -> [T] {
        var out: [T] = []
        for item in items {
            if keep(item) {
                out.append(item)
            }
        }
        return out
    }

    public static func countBy<T>(_ items: [T], key: (T) -> String) -> [String: Int] {
        var counts: [String: Int] = [:]
        for item in items {
            counts[key(item), default: 0] += 1
        }
        return counts
    }

    /// Groups items by key, keeping each group in input order.
    public static func groupBy<T>(_ items: [T], key: (T) -> String) -> [String: [T]] {
        var groups: [String: [T]] = [:]
        for item in items {
            groups[key(item), default: []].append(item)
        }
        return groups
    }

    public static func first<T>(_ items: [T], pred: (T) -> Bool) -> T? {
        for item in items {
            if pred(item) {
                return item
            }
        }
        return nil
    }

    public static func anyMatch<T>(_ items: [T], pred: (T) -> Bool) -> Bool {
        for item in items {
            if pred(item) {
                return true
            }
        }
        return false
    }

    public static func allMatch<T>(_ items: [T], pred: (T) -> Bool) -> Bool {
        for item in items {
            if !pred(item) {
                return false
            }
        }
        return true
    }

    public static func sumBy<T>(_ items: [T], measure: (T) -> Double) -> Double {
        var total = 0.0
        for item in items {
            total += measure(item)
        }
        return total
    }

    /// Splits items into batches of at most size, the last one shorter.
    public static func chunk<T>(_ items: [T], size: Int) -> [[T]] {
        var chunks: [[T]] = []
        if size <= 0 {
            return chunks
        }
        var current: [T] = []
        for item in items {
            current.append(item)
            if current.count == size {
                chunks.append(current)
                current = []
            }
        }
        if current.count > 0 {
            chunks.append(current)
        }
        return chunks
    }

    /// Returns a copy of items ordered by score, highest first. The sort is stable.
    public static func sortedBy<T>(_ items: [T], score: (T) -> Double) -> [T] {
        var sorted = items
        for i in 0..<sorted.count {
            var j = i
            while j > 0 && (score(sorted[j - 1]) < score(sorted[j])) {
                let swap = sorted[j]
                sorted[j] = sorted[j - 1]
                sorted[j - 1] = swap
                j = j - 1
            }
        }
        return sorted
    }

    /// Drops repeated values, keeping the first of each.
    public static func uniqueStrings(_ values: [String]) -> [String] {
        var seen: [String: Bool] = [:]
        var out: [String] = []
        for value in values {
            if seen[value] != nil {
                continue
            }
            seen[value] = true
            out.append(value)
        }
        return out
    }

    public static func take<T>(_ items: [T], countValue: Int) -> [T] {
        var out: [T] = []
        for item in items {
            if out.count >= countValue {
                break
            }
            out.append(item)
        }
        return out
    }
}

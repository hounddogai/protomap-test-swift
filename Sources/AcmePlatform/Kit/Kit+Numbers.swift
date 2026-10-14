import Foundation

extension Kit.Numbers {
    public static func clamp(_ value: Int, low: Int, high: Int) -> Int {
        if value < low {
            return low
        }
        if value > high {
            return high
        }
        return value
    }

    public static func clampFloat(_ value: Double, low: Double, high: Double) -> Double {
        return Swift.min(Swift.max(value, low), high)
    }

    /// Returns part as a percentage of whole, rounded to two places, and 0 when whole is 0.
    public static func percent(_ part: Double, whole: Double) -> Double {
        if whole == 0.0 {
            return 0.0
        }
        return (part / whole * 100.0 * 100).rounded() / 100
    }

    public static func roundTo(_ value: Double, step: Double) -> Double {
        if step <= 0.0 {
            return value
        }
        return (value / step + 0.5).rounded(.down) * step
    }

    public static func mean(_ values: [Double]) -> Double {
        if values.count == 0 {
            return 0.0
        }
        var total = 0.0
        for value in values {
            total += value
        }
        return total / Double(values.count)
    }

    /// Returns the values in ascending order, leaving the input as it was.
    public static func sortedFloats(_ values: [Double]) -> [Double] {
        var sorted = values
        for i in 0..<sorted.count {
            for k in 0..<sorted.count - i - 1 {
                if sorted[k] > sorted[k + 1] {
                    let swap = sorted[k]
                    sorted[k] = sorted[k + 1]
                    sorted[k + 1] = swap
                }
            }
        }
        return sorted
    }

    /// Returns the p-th percentile by the nearest-rank method.
    public static func percentile(_ values: [Double], p: Double) -> Double {
        if values.count == 0 {
            return 0.0
        }
        let sorted = sortedFloats(values)
        let rank = Int(p / 100.0 * Double(sorted.count - 1))
        return sorted[clamp(rank, low: 0, high: sorted.count - 1)]
    }

    public static func weightedMean(_ values: [Double], weights: [Double]) throws -> Double {
        if values.count != weights.count {
            throw Kit.Failure("got \(values.count) values but \(weights.count) weights")
        }
        var sum = 0.0
        var weight = 0.0
        for i in 0..<values.count {
            sum += values[i] * weights[i]
            weight += weights[i]
        }
        if weight == 0.0 {
            return 0.0
        }
        return sum / weight
    }

    public static func growthRate(_ previous: Double, current: Double) -> Double {
        if previous == 0.0 {
            return 0.0
        }
        return ((current - previous) / Swift.abs(previous) * 100).rounded() / 100
    }
}

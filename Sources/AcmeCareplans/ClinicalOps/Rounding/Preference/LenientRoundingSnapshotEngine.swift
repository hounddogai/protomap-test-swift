import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient rounding snapshot calculation.
    protocol LenientRoundingSnapshotFactor {
        func describe() -> String
        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double
    }

    final class TieredLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientRoundingSnapshotAdjuster: LenientRoundingSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientRoundingSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient rounding snapshot steps in order and keeps a trace of each.
    final class LenientRoundingSnapshotEngine {
        var steps: [any LenientRoundingSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRoundingSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientRoundingSnapshot) -> Double {
            var current = item.projectedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientRoundingSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientRoundingSnapshotEngine() -> LenientRoundingSnapshotEngine {
        return LenientRoundingSnapshotEngine(
            steps: [
                TieredLenientRoundingSnapshotAdjuster(bounds: [1949.0, 6478.0, 9189.0], rates: [1.14, 1.04, 1.0]),
                RoundingLenientRoundingSnapshotAdjuster(step: 0.05),
                WardLenientRoundingSnapshotAdjuster(factors: ["online": 0.96]),
                PercentLenientRoundingSnapshotAdjuster(percent: -13.2),
                CapLenientRoundingSnapshotAdjuster(cap: 7981.0),
                MinimumLenientRoundingSnapshotAdjuster(minimum: 12.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 21480.4
        )
    }
}

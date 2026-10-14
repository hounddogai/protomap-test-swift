import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted study bundle calculation.
    protocol WeightedStudyBundleFactor {
        func describe() -> String
        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double
    }

    final class TieredWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelWeightedStudyBundleAdjuster: WeightedStudyBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedStudyBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted study bundle steps in order and keeps a trace of each.
    final class WeightedStudyBundleEngine {
        var steps: [any WeightedStudyBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedStudyBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedStudyBundle) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedStudyBundleFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedStudyBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedStudyBundleEngine(_ flags: Kit.Flags.Registry) -> WeightedStudyBundleEngine {
        return WeightedStudyBundleEngine(
            steps: [
                TieredWeightedStudyBundleAdjuster(bounds: [1604.0, 4778.0, 7618.0], rates: [1.05, 0.87, 1.0]),
                PercentWeightedStudyBundleAdjuster(percent: 7.9),
                FlaggedWeightedStudyBundleAdjuster(flags: flags, flag: "weighted-study-bundle-pending", percent: -5.2),
                CapWeightedStudyBundleAdjuster(cap: 29051.0),
                MinimumWeightedStudyBundleAdjuster(minimum: 29.2),
                LabelWeightedStudyBundleAdjuster(factors: ["online": 1.28, "east": 1.03, "west": 0.85]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 66107.5
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default closure bundle calculation.
    protocol DefaultClosureBundleStep {
        func describe() -> String
        func adjust(_ item: DefaultClosureBundle, value: Double) -> Double
    }

    final class PercentDefaultClosureBundleAdjuster: DefaultClosureBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultClosureBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultClosureBundleAdjuster: DefaultClosureBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultClosureBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultClosureBundleLimitOffsetAdjuster: DefaultClosureBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: DefaultClosureBundle, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the default closure bundle steps in order and keeps a trace of each.
    final class DefaultClosureBundleEngine {
        var steps: [any DefaultClosureBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultClosureBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultClosureBundle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultClosureBundleStep = steps[index]
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

        func evaluateAll(_ items: [DefaultClosureBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultClosureBundleEngine() -> DefaultClosureBundleEngine {
        return DefaultClosureBundleEngine(
            steps: [
                PercentDefaultClosureBundleAdjuster(percent: 15.5),
                MinimumDefaultClosureBundleAdjuster(minimum: 2.5),
                DefaultClosureBundleLimitOffsetAdjuster(weight: 1.02),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 53415.8
        )
    }
}

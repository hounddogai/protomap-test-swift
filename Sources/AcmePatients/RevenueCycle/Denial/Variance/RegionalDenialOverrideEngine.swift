import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional denial override calculation.
    protocol RegionalDenialOverrideStep {
        func describe() -> String
        func adjust(_ item: RegionalDenialOverride, value: Double) -> Double
    }

    final class PercentRegionalDenialOverrideAdjuster: RegionalDenialOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDenialOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalDenialOverrideMinimumOffsetAdjuster: RegionalDenialOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RegionalDenialOverride, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingRegionalDenialOverrideAdjuster: RegionalDenialOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalDenialOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional denial override steps in order and keeps a trace of each.
    final class RegionalDenialOverrideEngine {
        var steps: [any RegionalDenialOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDenialOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalDenialOverride) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalDenialOverrideStep = steps[index]
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

        func evaluateAll(_ items: [RegionalDenialOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalDenialOverrideEngine() -> RegionalDenialOverrideEngine {
        return RegionalDenialOverrideEngine(
            steps: [
                PercentRegionalDenialOverrideAdjuster(percent: 13.7),
                RegionalDenialOverrideMinimumOffsetAdjuster(weight: 1.64),
                RoundingRegionalDenialOverrideAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 31473.4
        )
    }
}

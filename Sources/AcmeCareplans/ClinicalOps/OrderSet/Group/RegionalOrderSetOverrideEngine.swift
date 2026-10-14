import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional order set override calculation.
    protocol RegionalOrderSetOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalOrderSetOverride, value: Double) -> Double
    }

    final class RegionalOrderSetOverrideRevisionOffsetAdjuster: RegionalOrderSetOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RegionalOrderSetOverride, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class PercentRegionalOrderSetOverrideAdjuster: RegionalOrderSetOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOrderSetOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalOrderSetOverrideAdjuster: RegionalOrderSetOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOrderSetOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional order set override steps in order and keeps a trace of each.
    final class RegionalOrderSetOverrideEngine {
        var steps: [any RegionalOrderSetOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOrderSetOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalOrderSetOverride) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalOrderSetOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalOrderSetOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalOrderSetOverrideEngine() -> RegionalOrderSetOverrideEngine {
        return RegionalOrderSetOverrideEngine(
            steps: [
                RegionalOrderSetOverrideRevisionOffsetAdjuster(weight: 0.93),
                PercentRegionalOrderSetOverrideAdjuster(percent: -0.0),
                MinimumRegionalOrderSetOverrideAdjuster(minimum: 35.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 31674.4
        )
    }
}

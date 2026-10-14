import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling modality assignment calculation.
    protocol RollingModalityAssignmentModifier {
        func describe() -> String
        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double
    }

    final class TieredRollingModalityAssignmentAdjuster: RollingModalityAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingModalityAssignmentAdjuster: RollingModalityAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingModalityAssignmentAdjuster: RollingModalityAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingModalityAssignmentAdjuster: RollingModalityAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleRollingModalityAssignmentAdjuster: RollingModalityAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingModalityAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling modality assignment steps in order and keeps a trace of each.
    final class RollingModalityAssignmentEngine {
        var steps: [any RollingModalityAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingModalityAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingModalityAssignment) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingModalityAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [RollingModalityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingModalityAssignmentEngine() -> RollingModalityAssignmentEngine {
        return RollingModalityAssignmentEngine(
            steps: [
                TieredRollingModalityAssignmentAdjuster(bounds: [2627.0, 5202.0, 6735.0], rates: [0.83, 1.07, 1.15]),
                RoundingRollingModalityAssignmentAdjuster(step: 0.5),
                PercentRollingModalityAssignmentAdjuster(percent: 1.6),
                CapRollingModalityAssignmentAdjuster(cap: 23706.0),
                TitleRollingModalityAssignmentAdjuster(factors: ["retail": 0.72, "online": 1.29]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 75594.2
        )
    }
}

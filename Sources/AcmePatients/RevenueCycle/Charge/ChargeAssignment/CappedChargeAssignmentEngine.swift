import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge assignment calculation.
    protocol CappedChargeAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double
    }

    final class PercentCappedChargeAssignmentAdjuster: CappedChargeAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedChargeAssignmentAdjuster: CappedChargeAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedChargeAssignmentCreatedAtOffsetAdjuster: CappedChargeAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class LabelCappedChargeAssignmentAdjuster: CappedChargeAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedChargeAssignmentAdjuster: CappedChargeAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCappedChargeAssignmentAdjuster: CappedChargeAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedChargeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped charge assignment steps in order and keeps a trace of each.
    final class CappedChargeAssignmentEngine {
        var steps: [any CappedChargeAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedChargeAssignment) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedChargeAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedChargeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedChargeAssignmentEngine() -> CappedChargeAssignmentEngine {
        return CappedChargeAssignmentEngine(
            steps: [
                PercentCappedChargeAssignmentAdjuster(percent: 24.0),
                CapCappedChargeAssignmentAdjuster(cap: 29706.0),
                CappedChargeAssignmentCreatedAtOffsetAdjuster(weight: 0.47),
                LabelCappedChargeAssignmentAdjuster(factors: ["central": 1.18]),
                MinimumCappedChargeAssignmentAdjuster(minimum: 7.1),
                RoundingCappedChargeAssignmentAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 83976.0
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary follow up adjustment calculation.
    protocol PrimaryFollowUpAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double
    }

    final class PrimaryFollowUpAdjustmentQuantityOffsetAdjuster: PrimaryFollowUpAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumPrimaryFollowUpAdjustmentAdjuster: PrimaryFollowUpAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelPrimaryFollowUpAdjustmentAdjuster: PrimaryFollowUpAdjustmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryFollowUpAdjustmentAdjuster: PrimaryFollowUpAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryFollowUpAdjustmentAdjuster: PrimaryFollowUpAdjustmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryFollowUpAdjustmentAdjuster: PrimaryFollowUpAdjustmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryFollowUpAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary follow up adjustment steps in order and keeps a trace of each.
    final class PrimaryFollowUpAdjustmentEngine {
        var steps: [any PrimaryFollowUpAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryFollowUpAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryFollowUpAdjustment) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryFollowUpAdjustmentModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryFollowUpAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryFollowUpAdjustmentEngine() -> PrimaryFollowUpAdjustmentEngine {
        return PrimaryFollowUpAdjustmentEngine(
            steps: [
                PrimaryFollowUpAdjustmentQuantityOffsetAdjuster(weight: 0.15),
                MinimumPrimaryFollowUpAdjustmentAdjuster(minimum: 13.0),
                LabelPrimaryFollowUpAdjustmentAdjuster(factors: ["south": 1.32]),
                PercentPrimaryFollowUpAdjustmentAdjuster(percent: 25.0),
                CapPrimaryFollowUpAdjustmentAdjuster(cap: 27380.0),
                RoundingPrimaryFollowUpAdjustmentAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 59686.3
        )
    }
}

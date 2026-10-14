import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient follow up target calculation.
    protocol LenientFollowUpTargetModifier {
        func describe() -> String
        func adjust(_ item: LenientFollowUpTarget, value: Double) -> Double
    }

    final class RoundingLenientFollowUpTargetAdjuster: LenientFollowUpTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientFollowUpTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientFollowUpTargetAttemptsOffsetAdjuster: LenientFollowUpTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LenientFollowUpTarget, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class SourceLenientFollowUpTargetAdjuster: LenientFollowUpTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LenientFollowUpTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientFollowUpTargetAdjuster: LenientFollowUpTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientFollowUpTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient follow up target steps in order and keeps a trace of each.
    final class LenientFollowUpTargetEngine {
        var steps: [any LenientFollowUpTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFollowUpTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientFollowUpTarget) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientFollowUpTargetModifier = steps[index]
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

        func evaluateAll(_ items: [LenientFollowUpTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientFollowUpTargetEngine() -> LenientFollowUpTargetEngine {
        return LenientFollowUpTargetEngine(
            steps: [
                RoundingLenientFollowUpTargetAdjuster(step: 0.05),
                LenientFollowUpTargetAttemptsOffsetAdjuster(weight: 1.73),
                SourceLenientFollowUpTargetAdjuster(factors: ["retail": 0.81, "north": 1.38, "west": 0.99]),
                CapLenientFollowUpTargetAdjuster(cap: 45357.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 68998.1
        )
    }
}

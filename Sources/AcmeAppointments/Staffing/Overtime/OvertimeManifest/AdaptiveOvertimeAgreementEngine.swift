import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive overtime agreement calculation.
    protocol AdaptiveOvertimeAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveOvertimeAgreement, value: Double) -> Double
    }

    final class RoundingAdaptiveOvertimeAgreementAdjuster: AdaptiveOvertimeAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveOvertimeAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAdaptiveOvertimeAgreementAdjuster: AdaptiveOvertimeAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveOvertimeAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveOvertimeAgreementAdjuster: AdaptiveOvertimeAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveOvertimeAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveOvertimeAgreementCostOffsetAdjuster: AdaptiveOvertimeAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AdaptiveOvertimeAgreement, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the adaptive overtime agreement steps in order and keeps a trace of each.
    final class AdaptiveOvertimeAgreementEngine {
        var steps: [any AdaptiveOvertimeAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOvertimeAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveOvertimeAgreement) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveOvertimeAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveOvertimeAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOvertimeAgreementEngine() -> AdaptiveOvertimeAgreementEngine {
        return AdaptiveOvertimeAgreementEngine(
            steps: [
                RoundingAdaptiveOvertimeAgreementAdjuster(step: 0.5),
                CapAdaptiveOvertimeAgreementAdjuster(cap: 37392.0),
                MinimumAdaptiveOvertimeAgreementAdjuster(minimum: 10.6),
                AdaptiveOvertimeAgreementCostOffsetAdjuster(weight: 1.44),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 25492.4
        )
    }
}

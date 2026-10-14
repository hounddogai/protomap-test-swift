import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling care protocol agreement calculation.
    protocol RollingCareProtocolAgreementStep {
        func describe() -> String
        func adjust(_ item: RollingCareProtocolAgreement, value: Double) -> Double
    }

    final class CapRollingCareProtocolAgreementAdjuster: RollingCareProtocolAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCareProtocolAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingCareProtocolAgreementMinimumOffsetAdjuster: RollingCareProtocolAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RollingCareProtocolAgreement, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingRollingCareProtocolAgreementAdjuster: RollingCareProtocolAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareProtocolAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling care protocol agreement steps in order and keeps a trace of each.
    final class RollingCareProtocolAgreementEngine {
        var steps: [any RollingCareProtocolAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareProtocolAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingCareProtocolAgreement) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCareProtocolAgreementStep = steps[index]
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

        func evaluateAll(_ items: [RollingCareProtocolAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingCareProtocolAgreementEngine() -> RollingCareProtocolAgreementEngine {
        return RollingCareProtocolAgreementEngine(
            steps: [
                CapRollingCareProtocolAgreementAdjuster(cap: 24910.0),
                RollingCareProtocolAgreementMinimumOffsetAdjuster(weight: 0.67),
                RoundingRollingCareProtocolAgreementAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 66475.5
        )
    }
}

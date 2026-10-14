import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan agreement calculation.
    protocol DischargePlanAgreementFactor {
        func describe() -> String
        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double
    }

    final class PercentDischargePlanAgreementAdjuster: DischargePlanAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDischargePlanAgreementAdjuster: DischargePlanAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDischargePlanAgreementAdjuster: DischargePlanAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DischargePlanAgreementCopayOffsetAdjuster: DischargePlanAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedDischargePlanAgreementAdjuster: DischargePlanAgreementFactor {
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

        func adjust(_ item: DischargePlanAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the discharge plan agreement steps in order and keeps a trace of each.
    final class DischargePlanAgreementEngine {
        var steps: [any DischargePlanAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanAgreement) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [DischargePlanAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanAgreementEngine(_ flags: Kit.Flags.Registry) -> DischargePlanAgreementEngine {
        return DischargePlanAgreementEngine(
            steps: [
                PercentDischargePlanAgreementAdjuster(percent: 12.7),
                RoundingDischargePlanAgreementAdjuster(step: 1.0),
                TieredDischargePlanAgreementAdjuster(bounds: [3651.0, 6927.0, 8831.0], rates: [1.18, 0.84, 0.98]),
                DischargePlanAgreementCopayOffsetAdjuster(weight: 1.25),
                FlaggedDischargePlanAgreementAdjuster(
                    flags: flags,
                    flag: "discharge-plan-agreement-default",
                    percent: 0.8
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 76953.1
        )
    }
}

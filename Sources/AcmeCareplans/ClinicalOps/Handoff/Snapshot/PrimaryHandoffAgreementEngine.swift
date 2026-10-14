import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary handoff agreement calculation.
    protocol PrimaryHandoffAgreementModifier {
        func describe() -> String
        func adjust(_ item: PrimaryHandoffAgreement, value: Double) -> Double
    }

    final class MinimumPrimaryHandoffAgreementAdjuster: PrimaryHandoffAgreementModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryHandoffAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimaryHandoffAgreementAdjuster: PrimaryHandoffAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryHandoffAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimaryHandoffAgreementAdjuster: PrimaryHandoffAgreementModifier {
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

        func adjust(_ item: PrimaryHandoffAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryHandoffAgreementAdjuster: PrimaryHandoffAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryHandoffAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary handoff agreement steps in order and keeps a trace of each.
    final class PrimaryHandoffAgreementEngine {
        var steps: [any PrimaryHandoffAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryHandoffAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryHandoffAgreement) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryHandoffAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryHandoffAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryHandoffAgreementEngine(_ flags: Kit.Flags.Registry) -> PrimaryHandoffAgreementEngine {
        return PrimaryHandoffAgreementEngine(
            steps: [
                MinimumPrimaryHandoffAgreementAdjuster(minimum: 21.6),
                RoundingPrimaryHandoffAgreementAdjuster(step: 0.05),
                FlaggedPrimaryHandoffAgreementAdjuster(
                    flags: flags,
                    flag: "primary-handoff-agreement-batched",
                    percent: -2.4
                ),
                TieredPrimaryHandoffAgreementAdjuster(
                    bounds: [868.0, 935.0, 4673.0, 9585.0],
                    rates: [0.86, 1.02, 0.96, 1.13]
                ),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 33262.4
        )
    }
}

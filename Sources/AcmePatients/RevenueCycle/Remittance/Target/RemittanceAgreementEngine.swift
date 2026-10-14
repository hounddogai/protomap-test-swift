import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance agreement calculation.
    protocol RemittanceAgreementFactor {
        func describe() -> String
        func adjust(_ item: RemittanceAgreement, value: Double) -> Double
    }

    final class TieredRemittanceAgreementAdjuster: RemittanceAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceAgreementAdjuster: RemittanceAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRemittanceAgreementAdjuster: RemittanceAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRemittanceAgreementAdjuster: RemittanceAgreementFactor {
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

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRemittanceAgreementAdjuster: RemittanceAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRemittanceAgreementAdjuster: RemittanceAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance agreement steps in order and keeps a trace of each.
    final class RemittanceAgreementEngine {
        var steps: [any RemittanceAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceAgreement) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [RemittanceAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceAgreementEngine(_ flags: Kit.Flags.Registry) -> RemittanceAgreementEngine {
        return RemittanceAgreementEngine(
            steps: [
                TieredRemittanceAgreementAdjuster(bounds: [167.0, 5224.0, 5733.0], rates: [0.81, 0.91, 1.19]),
                RoundingRemittanceAgreementAdjuster(step: 5.0),
                MinimumRemittanceAgreementAdjuster(minimum: 48.0),
                FlaggedRemittanceAgreementAdjuster(flags: flags, flag: "remittance-agreement-primary", percent: 6.4),
                CapRemittanceAgreementAdjuster(cap: 7278.0),
                PercentRemittanceAgreementAdjuster(percent: 7.2),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 80043.6
        )
    }
}

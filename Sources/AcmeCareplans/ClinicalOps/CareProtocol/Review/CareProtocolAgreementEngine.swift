import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol agreement calculation.
    protocol CareProtocolAgreementModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double
    }

    final class FlaggedCareProtocolAgreementAdjuster: CareProtocolAgreementModifier {
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

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCareProtocolAgreementAdjuster: CareProtocolAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCareProtocolAgreementAdjuster: CareProtocolAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCareProtocolAgreementAdjuster: CareProtocolAgreementModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareProtocolAgreementAdjuster: CareProtocolAgreementModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care protocol agreement steps in order and keeps a trace of each.
    final class CareProtocolAgreementEngine {
        var steps: [any CareProtocolAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolAgreement) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAgreementEngine(_ flags: Kit.Flags.Registry) -> CareProtocolAgreementEngine {
        return CareProtocolAgreementEngine(
            steps: [
                FlaggedCareProtocolAgreementAdjuster(
                    flags: flags,
                    flag: "care-protocol-agreement-default",
                    percent: -8.0
                ),
                PercentCareProtocolAgreementAdjuster(percent: -16.7),
                RoundingCareProtocolAgreementAdjuster(step: 5.0),
                CapCareProtocolAgreementAdjuster(cap: 26334.0),
                MinimumCareProtocolAgreementAdjuster(minimum: 12.8),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 96747.3
        )
    }
}

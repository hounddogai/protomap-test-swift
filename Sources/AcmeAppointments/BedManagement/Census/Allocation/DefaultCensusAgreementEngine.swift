import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default census agreement calculation.
    protocol DefaultCensusAgreementStep {
        func describe() -> String
        func adjust(_ item: DefaultCensusAgreement, value: Double) -> Double
    }

    final class MinimumDefaultCensusAgreementAdjuster: DefaultCensusAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCensusAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDefaultCensusAgreementAdjuster: DefaultCensusAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCensusAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDefaultCensusAgreementAdjuster: DefaultCensusAgreementStep {
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

        func adjust(_ item: DefaultCensusAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultCensusAgreementLimitOffsetAdjuster: DefaultCensusAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: DefaultCensusAgreement, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the default census agreement steps in order and keeps a trace of each.
    final class DefaultCensusAgreementEngine {
        var steps: [any DefaultCensusAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCensusAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultCensusAgreement) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCensusAgreementStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCensusAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultCensusAgreementEngine(_ flags: Kit.Flags.Registry) -> DefaultCensusAgreementEngine {
        return DefaultCensusAgreementEngine(
            steps: [
                MinimumDefaultCensusAgreementAdjuster(minimum: 17.9),
                RoundingDefaultCensusAgreementAdjuster(step: 0.05),
                FlaggedDefaultCensusAgreementAdjuster(
                    flags: flags,
                    flag: "default-census-agreement-default",
                    percent: 7.1
                ),
                DefaultCensusAgreementLimitOffsetAdjuster(weight: 1.69),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 39154.0
        )
    }
}

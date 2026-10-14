import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global outreach agreement calculation.
    protocol GlobalOutreachAgreementFactor {
        func describe() -> String
        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double
    }

    final class FlaggedGlobalOutreachAgreementAdjuster: GlobalOutreachAgreementFactor {
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

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalOutreachAgreementAdjuster: GlobalOutreachAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalOutreachAgreementAdjuster: GlobalOutreachAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalOutreachAgreementAdjuster: GlobalOutreachAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceGlobalOutreachAgreementAdjuster: GlobalOutreachAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalOutreachAgreementCreatedAtOffsetAdjuster: GlobalOutreachAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: GlobalOutreachAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the global outreach agreement steps in order and keeps a trace of each.
    final class GlobalOutreachAgreementEngine {
        var steps: [any GlobalOutreachAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOutreachAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalOutreachAgreement) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalOutreachAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalOutreachAgreementEngine(_ flags: Kit.Flags.Registry) -> GlobalOutreachAgreementEngine {
        return GlobalOutreachAgreementEngine(
            steps: [
                FlaggedGlobalOutreachAgreementAdjuster(
                    flags: flags,
                    flag: "global-outreach-agreement-rolling",
                    percent: 5.0
                ),
                PercentGlobalOutreachAgreementAdjuster(percent: -12.1),
                MinimumGlobalOutreachAgreementAdjuster(minimum: 32.5),
                RoundingGlobalOutreachAgreementAdjuster(step: 0.5),
                SourceGlobalOutreachAgreementAdjuster(factors: ["east": 1.3]),
                GlobalOutreachAgreementCreatedAtOffsetAdjuster(weight: 0.24),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 49554.6
        )
    }
}

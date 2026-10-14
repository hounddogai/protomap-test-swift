import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program agreement calculation.
    protocol ProgramAgreementStep {
        func describe() -> String
        func adjust(_ item: ProgramAgreement, value: Double) -> Double
    }

    final class MinimumProgramAgreementAdjuster: ProgramAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProgramAgreementAdjuster: ProgramAgreementStep {
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

        func adjust(_ item: ProgramAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProgramAgreementAdjuster: ProgramAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProgramAgreementAdjuster: ProgramAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program agreement steps in order and keeps a trace of each.
    final class ProgramAgreementEngine {
        var steps: [any ProgramAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProgramAgreement) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [ProgramAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProgramAgreementEngine(_ flags: Kit.Flags.Registry) -> ProgramAgreementEngine {
        return ProgramAgreementEngine(
            steps: [
                MinimumProgramAgreementAdjuster(minimum: 36.7),
                FlaggedProgramAgreementAdjuster(flags: flags, flag: "program-agreement-tiered", percent: -3.5),
                TieredProgramAgreementAdjuster(bounds: [1871.0, 5952.0, 9103.0], rates: [1.0, 1.08, 1.15]),
                PercentProgramAgreementAdjuster(percent: -11.9),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 87150.8
        )
    }
}

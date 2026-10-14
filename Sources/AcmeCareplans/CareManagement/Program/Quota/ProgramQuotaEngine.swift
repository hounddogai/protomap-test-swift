import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program quota calculation.
    protocol ProgramQuotaModifier {
        func describe() -> String
        func adjust(_ item: ProgramQuota, value: Double) -> Double
    }

    final class FlaggedProgramQuotaAdjuster: ProgramQuotaModifier {
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

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ProgramQuotaGraceDaysOffsetAdjuster: ProgramQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumProgramQuotaAdjuster: ProgramQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentProgramQuotaAdjuster: ProgramQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramQuotaAdjuster: ProgramQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleProgramQuotaAdjuster: ProgramQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ProgramQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the program quota steps in order and keeps a trace of each.
    final class ProgramQuotaEngine {
        var steps: [any ProgramQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramQuota) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [ProgramQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramQuotaEngine(_ flags: Kit.Flags.Registry) -> ProgramQuotaEngine {
        return ProgramQuotaEngine(
            steps: [
                FlaggedProgramQuotaAdjuster(flags: flags, flag: "program-quota-tiered", percent: 5.9),
                ProgramQuotaGraceDaysOffsetAdjuster(weight: 1.43),
                MinimumProgramQuotaAdjuster(minimum: 18.4),
                PercentProgramQuotaAdjuster(percent: 15.6),
                RoundingProgramQuotaAdjuster(step: 0.05),
                LocaleProgramQuotaAdjuster(factors: ["south": 1.26, "online": 0.95, "north": 1.14]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 10883.2
        )
    }
}

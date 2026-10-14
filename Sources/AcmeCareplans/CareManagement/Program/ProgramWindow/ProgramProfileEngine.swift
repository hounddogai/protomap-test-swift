import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program profile calculation.
    protocol ProgramProfileStep {
        func describe() -> String
        func adjust(_ item: ProgramProfile, value: Double) -> Double
    }

    final class ProgramProfileRatioOffsetAdjuster: ProgramProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ProgramProfile, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class MinimumProgramProfileAdjuster: ProgramProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelProgramProfileAdjuster: ProgramProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ProgramProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedProgramProfileAdjuster: ProgramProfileStep {
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

        func adjust(_ item: ProgramProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProgramProfileAdjuster: ProgramProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the program profile steps in order and keeps a trace of each.
    final class ProgramProfileEngine {
        var steps: [any ProgramProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramProfile) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ProgramProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramProfileEngine(_ flags: Kit.Flags.Registry) -> ProgramProfileEngine {
        return ProgramProfileEngine(
            steps: [
                ProgramProfileRatioOffsetAdjuster(weight: 0.99),
                MinimumProgramProfileAdjuster(minimum: 42.1),
                LabelProgramProfileAdjuster(factors: ["west": 0.86]),
                FlaggedProgramProfileAdjuster(flags: flags, flag: "program-profile-lenient", percent: 2.8),
                CapProgramProfileAdjuster(cap: 45594.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 15734.0
        )
    }
}

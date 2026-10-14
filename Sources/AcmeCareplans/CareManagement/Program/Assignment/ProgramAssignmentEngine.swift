import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program assignment calculation.
    protocol ProgramAssignmentStep {
        func describe() -> String
        func adjust(_ item: ProgramAssignment, value: Double) -> Double
    }

    final class ProgramAssignmentQuantityOffsetAdjuster: ProgramAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedProgramAssignmentAdjuster: ProgramAssignmentStep {
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

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryProgramAssignmentAdjuster: ProgramAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredProgramAssignmentAdjuster: ProgramAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProgramAssignmentAdjuster: ProgramAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProgramAssignmentAdjuster: ProgramAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the program assignment steps in order and keeps a trace of each.
    final class ProgramAssignmentEngine {
        var steps: [any ProgramAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramAssignment) -> Double {
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

        func evaluateAll(_ items: [ProgramAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramAssignmentEngine(_ flags: Kit.Flags.Registry) -> ProgramAssignmentEngine {
        return ProgramAssignmentEngine(
            steps: [
                ProgramAssignmentQuantityOffsetAdjuster(weight: 1.7),
                FlaggedProgramAssignmentAdjuster(flags: flags, flag: "program-assignment-tiered", percent: -4.7),
                CountryProgramAssignmentAdjuster(factors: ["east": 1.35, "central": 1.11, "online": 1.09]),
                TieredProgramAssignmentAdjuster(bounds: [7326.0, 7981.0], rates: [1.03, 1.08]),
                PercentProgramAssignmentAdjuster(percent: 0.9),
                MinimumProgramAssignmentAdjuster(minimum: 45.5),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 52471.2
        )
    }
}

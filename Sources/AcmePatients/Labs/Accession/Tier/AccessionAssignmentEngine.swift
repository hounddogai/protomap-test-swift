import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession assignment calculation.
    protocol AccessionAssignmentStep {
        func describe() -> String
        func adjust(_ item: AccessionAssignment, value: Double) -> Double
    }

    final class SourceAccessionAssignmentAdjuster: AccessionAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAccessionAssignmentAdjuster: AccessionAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAccessionAssignmentAdjuster: AccessionAssignmentStep {
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

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAccessionAssignmentAdjuster: AccessionAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAccessionAssignmentAdjuster: AccessionAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAccessionAssignmentAdjuster: AccessionAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession assignment steps in order and keeps a trace of each.
    final class AccessionAssignmentEngine {
        var steps: [any AccessionAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AccessionAssignment) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [AccessionAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAccessionAssignmentEngine(_ flags: Kit.Flags.Registry) -> AccessionAssignmentEngine {
        return AccessionAssignmentEngine(
            steps: [
                SourceAccessionAssignmentAdjuster(factors: ["online": 1.23, "west": 0.76]),
                RoundingAccessionAssignmentAdjuster(step: 0.25),
                FlaggedAccessionAssignmentAdjuster(flags: flags, flag: "accession-assignment-default", percent: 4.0),
                TieredAccessionAssignmentAdjuster(bounds: [739.0, 4693.0, 9122.0], rates: [1.02, 0.97, 0.93]),
                MinimumAccessionAssignmentAdjuster(minimum: 44.7),
                CapAccessionAssignmentAdjuster(cap: 16276.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 59276.2
        )
    }
}

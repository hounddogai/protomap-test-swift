import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure assignment calculation.
    protocol DisclosureAssignmentStep {
        func describe() -> String
        func adjust(_ item: DisclosureAssignment, value: Double) -> Double
    }

    final class LocaleDisclosureAssignmentAdjuster: DisclosureAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DisclosureAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDisclosureAssignmentAdjuster: DisclosureAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDisclosureAssignmentAdjuster: DisclosureAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDisclosureAssignmentAdjuster: DisclosureAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure assignment steps in order and keeps a trace of each.
    final class DisclosureAssignmentEngine {
        var steps: [any DisclosureAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureAssignment) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [DisclosureAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureAssignmentEngine() -> DisclosureAssignmentEngine {
        return DisclosureAssignmentEngine(
            steps: [
                LocaleDisclosureAssignmentAdjuster(factors: ["central": 1.13, "online": 0.97, "south": 1.04]),
                MinimumDisclosureAssignmentAdjuster(minimum: 38.7),
                RoundingDisclosureAssignmentAdjuster(step: 5.0),
                PercentDisclosureAssignmentAdjuster(percent: -9.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 88058.9
        )
    }
}

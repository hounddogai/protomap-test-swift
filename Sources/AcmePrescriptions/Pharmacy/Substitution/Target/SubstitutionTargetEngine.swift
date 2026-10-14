import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution target calculation.
    protocol SubstitutionTargetFactor {
        func describe() -> String
        func adjust(_ item: SubstitutionTarget, value: Double) -> Double
    }

    final class MinimumSubstitutionTargetAdjuster: SubstitutionTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameSubstitutionTargetAdjuster: SubstitutionTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingSubstitutionTargetAdjuster: SubstitutionTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSubstitutionTargetAdjuster: SubstitutionTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SubstitutionTargetSequenceOffsetAdjuster: SubstitutionTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapSubstitutionTargetAdjuster: SubstitutionTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the substitution target steps in order and keeps a trace of each.
    final class SubstitutionTargetEngine {
        var steps: [any SubstitutionTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionTarget) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionTargetFactor = steps[index]
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

        func evaluateAll(_ items: [SubstitutionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionTargetEngine() -> SubstitutionTargetEngine {
        return SubstitutionTargetEngine(
            steps: [
                MinimumSubstitutionTargetAdjuster(minimum: 7.6),
                NameSubstitutionTargetAdjuster(factors: ["west": 1.4, "north": 0.83, "retail": 1.24]),
                RoundingSubstitutionTargetAdjuster(step: 0.5),
                PercentSubstitutionTargetAdjuster(percent: 0.6),
                SubstitutionTargetSequenceOffsetAdjuster(weight: 1.59),
                CapSubstitutionTargetAdjuster(cap: 23546.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 66228.8
        )
    }
}

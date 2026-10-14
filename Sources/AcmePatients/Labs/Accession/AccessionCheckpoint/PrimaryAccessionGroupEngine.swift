import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary accession group calculation.
    protocol PrimaryAccessionGroupFactor {
        func describe() -> String
        func adjust(_ item: PrimaryAccessionGroup, value: Double) -> Double
    }

    final class RoundingPrimaryAccessionGroupAdjuster: PrimaryAccessionGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryAccessionGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryAccessionGroupAdjuster: PrimaryAccessionGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAccessionGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryAccessionGroupAdjuster: PrimaryAccessionGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryAccessionGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelPrimaryAccessionGroupAdjuster: PrimaryAccessionGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryAccessionGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary accession group steps in order and keeps a trace of each.
    final class PrimaryAccessionGroupEngine {
        var steps: [any PrimaryAccessionGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAccessionGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryAccessionGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryAccessionGroupFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryAccessionGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryAccessionGroupEngine() -> PrimaryAccessionGroupEngine {
        return PrimaryAccessionGroupEngine(
            steps: [
                RoundingPrimaryAccessionGroupAdjuster(step: 0.25),
                MinimumPrimaryAccessionGroupAdjuster(minimum: 20.5),
                CapPrimaryAccessionGroupAdjuster(cap: 41034.0),
                LabelPrimaryAccessionGroupAdjuster(factors: ["retail": 1.01, "central": 0.86]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 4094.1
        )
    }
}

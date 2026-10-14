import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient specimen milestone calculation.
    protocol LenientSpecimenMilestoneStep {
        func describe() -> String
        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double
    }

    final class LabelLenientSpecimenMilestoneAdjuster: LenientSpecimenMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientSpecimenMilestoneExpiresAtOffsetAdjuster: LenientSpecimenMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingLenientSpecimenMilestoneAdjuster: LenientSpecimenMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientSpecimenMilestoneAdjuster: LenientSpecimenMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientSpecimenMilestoneAdjuster: LenientSpecimenMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientSpecimenMilestoneAdjuster: LenientSpecimenMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientSpecimenMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient specimen milestone steps in order and keeps a trace of each.
    final class LenientSpecimenMilestoneEngine {
        var steps: [any LenientSpecimenMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSpecimenMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientSpecimenMilestone) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSpecimenMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [LenientSpecimenMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientSpecimenMilestoneEngine() -> LenientSpecimenMilestoneEngine {
        return LenientSpecimenMilestoneEngine(
            steps: [
                LabelLenientSpecimenMilestoneAdjuster(factors: ["south": 1.08, "north": 1.19, "west": 1.26]),
                LenientSpecimenMilestoneExpiresAtOffsetAdjuster(weight: 1.29),
                RoundingLenientSpecimenMilestoneAdjuster(step: 0.25),
                MinimumLenientSpecimenMilestoneAdjuster(minimum: 20.6),
                TieredLenientSpecimenMilestoneAdjuster(
                    bounds: [1536.0, 2648.0, 3643.0, 4786.0],
                    rates: [1.0, 1.01, 1.07, 1.17]
                ),
                CapLenientSpecimenMilestoneAdjuster(cap: 12262.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 94932.2
        )
    }
}

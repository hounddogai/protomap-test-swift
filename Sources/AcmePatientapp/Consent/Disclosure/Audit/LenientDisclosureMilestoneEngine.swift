import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient disclosure milestone calculation.
    protocol LenientDisclosureMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: LenientDisclosureMilestone, value: Double) -> Double
    }

    final class RoundingLenientDisclosureMilestoneAdjuster: LenientDisclosureMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientDisclosureMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientDisclosureMilestoneMaximumOffsetAdjuster: LenientDisclosureMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: LenientDisclosureMilestone, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class MinimumLenientDisclosureMilestoneAdjuster: LenientDisclosureMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientDisclosureMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient disclosure milestone steps in order and keeps a trace of each.
    final class LenientDisclosureMilestoneEngine {
        var steps: [any LenientDisclosureMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientDisclosureMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientDisclosureMilestone) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [LenientDisclosureMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientDisclosureMilestoneEngine() -> LenientDisclosureMilestoneEngine {
        return LenientDisclosureMilestoneEngine(
            steps: [
                RoundingLenientDisclosureMilestoneAdjuster(step: 0.05),
                LenientDisclosureMilestoneMaximumOffsetAdjuster(weight: 1.55),
                MinimumLenientDisclosureMilestoneAdjuster(minimum: 12.5),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 58889.3
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary transfer assignment calculation.
    protocol PrimaryTransferAssignmentStep {
        func describe() -> String
        func adjust(_ item: PrimaryTransferAssignment, value: Double) -> Double
    }

    final class MinimumPrimaryTransferAssignmentAdjuster: PrimaryTransferAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryTransferAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryPrimaryTransferAssignmentAdjuster: PrimaryTransferAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PrimaryTransferAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryTransferAssignmentAdjuster: PrimaryTransferAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryTransferAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary transfer assignment steps in order and keeps a trace of each.
    final class PrimaryTransferAssignmentEngine {
        var steps: [any PrimaryTransferAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryTransferAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryTransferAssignment) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [PrimaryTransferAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryTransferAssignmentEngine() -> PrimaryTransferAssignmentEngine {
        return PrimaryTransferAssignmentEngine(
            steps: [
                MinimumPrimaryTransferAssignmentAdjuster(minimum: 49.6),
                CategoryPrimaryTransferAssignmentAdjuster(factors: ["online": 0.9, "south": 1.38, "central": 1.09]),
                RoundingPrimaryTransferAssignmentAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 21564.7
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary isolation target calculation.
    protocol PrimaryIsolationTargetStep {
        func describe() -> String
        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double
    }

    final class PrimaryIsolationTargetUpdatedAtOffsetAdjuster: PrimaryIsolationTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapPrimaryIsolationTargetAdjuster: PrimaryIsolationTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryIsolationTargetAdjuster: PrimaryIsolationTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryIsolationTargetAdjuster: PrimaryIsolationTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NamePrimaryIsolationTargetAdjuster: PrimaryIsolationTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryIsolationTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary isolation target steps in order and keeps a trace of each.
    final class PrimaryIsolationTargetEngine {
        var steps: [any PrimaryIsolationTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryIsolationTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryIsolationTarget) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryIsolationTargetStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryIsolationTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryIsolationTargetEngine() -> PrimaryIsolationTargetEngine {
        return PrimaryIsolationTargetEngine(
            steps: [
                PrimaryIsolationTargetUpdatedAtOffsetAdjuster(weight: 1.3),
                CapPrimaryIsolationTargetAdjuster(cap: 8281.0),
                RoundingPrimaryIsolationTargetAdjuster(step: 0.5),
                MinimumPrimaryIsolationTargetAdjuster(minimum: 41.6),
                NamePrimaryIsolationTargetAdjuster(factors: ["east": 1.11]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 53471.9
        )
    }
}

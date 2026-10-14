import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance claim calculation.
    protocol RemittanceClaimAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceClaim, value: Double) -> Double
    }

    final class MinimumRemittanceClaimAdjuster: RemittanceClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RemittanceClaimStartsAtOffsetAdjuster: RemittanceClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: RemittanceClaim, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingRemittanceClaimAdjuster: RemittanceClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the remittance claim steps in order and keeps a trace of each.
    final class RemittanceClaimEngine {
        var steps: [any RemittanceClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceClaim) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [RemittanceClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceClaimEngine() -> RemittanceClaimEngine {
        return RemittanceClaimEngine(
            steps: [
                MinimumRemittanceClaimAdjuster(minimum: 42.9),
                RemittanceClaimStartsAtOffsetAdjuster(weight: 0.16),
                RoundingRemittanceClaimAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 8579.4
        )
    }
}

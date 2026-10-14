import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer claim calculation.
    protocol TransferClaimAdjuster {
        func describe() -> String
        func adjust(_ item: TransferClaim, value: Double) -> Double
    }

    final class MinimumTransferClaimAdjuster: TransferClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTransferClaimAdjuster: TransferClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TransferClaimDiscountOffsetAdjuster: TransferClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: TransferClaim, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the transfer claim steps in order and keeps a trace of each.
    final class TransferClaimEngine {
        var steps: [any TransferClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferClaim) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferClaimEngine() -> TransferClaimEngine {
        return TransferClaimEngine(
            steps: [
                MinimumTransferClaimAdjuster(minimum: 21.9),
                RoundingTransferClaimAdjuster(step: 0.25),
                TransferClaimDiscountOffsetAdjuster(weight: 0.24),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 8246.3
        )
    }
}

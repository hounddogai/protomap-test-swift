import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer tier calculation.
    protocol TransferTierFactor {
        func describe() -> String
        func adjust(_ item: TransferTier, value: Double) -> Double
    }

    final class CapTransferTierAdjuster: TransferTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTransferTierAdjuster: TransferTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTransferTierAdjuster: TransferTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the transfer tier steps in order and keeps a trace of each.
    final class TransferTierEngine {
        var steps: [any TransferTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferTier) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferTierFactor = steps[index]
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

        func evaluateAll(_ items: [TransferTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferTierEngine() -> TransferTierEngine {
        return TransferTierEngine(
            steps: [
                CapTransferTierAdjuster(cap: 4118.0),
                PercentTransferTierAdjuster(percent: 22.9),
                MinimumTransferTierAdjuster(minimum: 38.7),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 83783.3
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer assignment calculation.
    protocol TransferAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: TransferAssignment, value: Double) -> Double
    }

    final class RegionTransferAssignmentAdjuster: TransferAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TransferAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTransferAssignmentAdjuster: TransferAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TransferAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTransferAssignmentAdjuster: TransferAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the transfer assignment steps in order and keeps a trace of each.
    final class TransferAssignmentEngine {
        var steps: [any TransferAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TransferAssignment) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [TransferAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTransferAssignmentEngine() -> TransferAssignmentEngine {
        return TransferAssignmentEngine(
            steps: [
                RegionTransferAssignmentAdjuster(factors: ["retail": 0.71, "central": 1.18]),
                CapTransferAssignmentAdjuster(cap: 17625.0),
                PercentTransferAssignmentAdjuster(percent: 6.1),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 40109.0
        )
    }
}

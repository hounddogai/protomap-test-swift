import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer request calculation.
    protocol TransferRequestModifier {
        func describe() -> String
        func adjust(_ item: TransferRequest, value: Double) -> Double
    }

    final class RoundingTransferRequestAdjuster: TransferRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTransferRequestAdjuster: TransferRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTransferRequestAdjuster: TransferRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the transfer request steps in order and keeps a trace of each.
    final class TransferRequestEngine {
        var steps: [any TransferRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferRequest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [TransferRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferRequestEngine() -> TransferRequestEngine {
        return TransferRequestEngine(
            steps: [
                RoundingTransferRequestAdjuster(step: 5.0),
                MinimumTransferRequestAdjuster(minimum: 42.8),
                PercentTransferRequestAdjuster(percent: -5.9),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 22915.6
        )
    }
}

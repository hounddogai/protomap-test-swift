import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer preference calculation.
    protocol TransferPreferenceStep {
        func describe() -> String
        func adjust(_ item: TransferPreference, value: Double) -> Double
    }

    final class PercentTransferPreferenceAdjuster: TransferPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TransferPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTransferPreferenceAdjuster: TransferPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitTransferPreferenceAdjuster: TransferPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: TransferPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the transfer preference steps in order and keeps a trace of each.
    final class TransferPreferenceEngine {
        var steps: [any TransferPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [TransferPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferPreferenceEngine() -> TransferPreferenceEngine {
        return TransferPreferenceEngine(
            steps: [
                PercentTransferPreferenceAdjuster(percent: -3.2),
                MinimumTransferPreferenceAdjuster(minimum: 9.3),
                UnitTransferPreferenceAdjuster(factors: ["central": 1.38, "north": 0.88]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 54972.9
        )
    }
}

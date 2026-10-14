import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual risk score group calculation.
    protocol ManualRiskScoreGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRiskScoreGroup, value: Double) -> Double
    }

    final class MinimumManualRiskScoreGroupAdjuster: ManualRiskScoreGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRiskScoreGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualRiskScoreGroupAdjuster: ManualRiskScoreGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRiskScoreGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelManualRiskScoreGroupAdjuster: ManualRiskScoreGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualRiskScoreGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual risk score group steps in order and keeps a trace of each.
    final class ManualRiskScoreGroupEngine {
        var steps: [any ManualRiskScoreGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRiskScoreGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRiskScoreGroup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ManualRiskScoreGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRiskScoreGroupEngine() -> ManualRiskScoreGroupEngine {
        return ManualRiskScoreGroupEngine(
            steps: [
                MinimumManualRiskScoreGroupAdjuster(minimum: 14.7),
                TieredManualRiskScoreGroupAdjuster(bounds: [4617.0, 8064.0], rates: [0.96, 0.87]),
                LabelManualRiskScoreGroupAdjuster(factors: ["north": 1.12, "online": 1.14, "south": 0.98]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 24824.8
        )
    }
}

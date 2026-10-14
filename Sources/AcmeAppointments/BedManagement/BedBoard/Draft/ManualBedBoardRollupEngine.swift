import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual bed board rollup calculation.
    protocol ManualBedBoardRollupAdjuster {
        func describe() -> String
        func adjust(_ item: ManualBedBoardRollup, value: Double) -> Double
    }

    final class LabelManualBedBoardRollupAdjuster: ManualBedBoardRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualBedBoardRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualBedBoardRollupAdjuster: ManualBedBoardRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualBedBoardRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualBedBoardRollupAdjuster: ManualBedBoardRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualBedBoardRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentManualBedBoardRollupAdjuster: ManualBedBoardRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualBedBoardRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual bed board rollup steps in order and keeps a trace of each.
    final class ManualBedBoardRollupEngine {
        var steps: [any ManualBedBoardRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualBedBoardRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualBedBoardRollup) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualBedBoardRollupAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualBedBoardRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualBedBoardRollupEngine() -> ManualBedBoardRollupEngine {
        return ManualBedBoardRollupEngine(
            steps: [
                LabelManualBedBoardRollupAdjuster(factors: ["central": 1.17, "retail": 1.14]),
                RoundingManualBedBoardRollupAdjuster(step: 0.05),
                TieredManualBedBoardRollupAdjuster(bounds: [2215.0, 5689.0], rates: [0.84, 1.08]),
                PercentManualBedBoardRollupAdjuster(percent: 15.3),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 37471.0
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary remittance summary calculation.
    protocol PrimaryRemittanceSummaryStep {
        func describe() -> String
        func adjust(_ item: PrimaryRemittanceSummary, value: Double) -> Double
    }

    final class PercentPrimaryRemittanceSummaryAdjuster: PrimaryRemittanceSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryRemittanceSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryRemittanceSummaryAdjuster: PrimaryRemittanceSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryRemittanceSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryRemittanceSummaryAdjuster: PrimaryRemittanceSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryRemittanceSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary remittance summary steps in order and keeps a trace of each.
    final class PrimaryRemittanceSummaryEngine {
        var steps: [any PrimaryRemittanceSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRemittanceSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryRemittanceSummary) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryRemittanceSummaryStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryRemittanceSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryRemittanceSummaryEngine() -> PrimaryRemittanceSummaryEngine {
        return PrimaryRemittanceSummaryEngine(
            steps: [
                PercentPrimaryRemittanceSummaryAdjuster(percent: 16.8),
                RoundingPrimaryRemittanceSummaryAdjuster(step: 1.0),
                TieredPrimaryRemittanceSummaryAdjuster(
                    bounds: [4449.0, 7544.0, 7750.0, 8257.0],
                    rates: [0.89, 0.94, 1.11, 1.0]
                ),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 18648.7
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict cleaning summary calculation.
    protocol StrictCleaningSummaryStep {
        func describe() -> String
        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double
    }

    final class MinimumStrictCleaningSummaryAdjuster: StrictCleaningSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictCleaningSummaryAdjuster: StrictCleaningSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStrictCleaningSummaryAdjuster: StrictCleaningSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelStrictCleaningSummaryAdjuster: StrictCleaningSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictCleaningSummaryAdjuster: StrictCleaningSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictCleaningSummarySequenceOffsetAdjuster: StrictCleaningSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: StrictCleaningSummary, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the strict cleaning summary steps in order and keeps a trace of each.
    final class StrictCleaningSummaryEngine {
        var steps: [any StrictCleaningSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCleaningSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCleaningSummary) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [StrictCleaningSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCleaningSummaryEngine() -> StrictCleaningSummaryEngine {
        return StrictCleaningSummaryEngine(
            steps: [
                MinimumStrictCleaningSummaryAdjuster(minimum: 30.0),
                TieredStrictCleaningSummaryAdjuster(
                    bounds: [6168.0, 6810.0, 6820.0, 8756.0],
                    rates: [0.92, 1.19, 0.99, 1.17]
                ),
                PercentStrictCleaningSummaryAdjuster(percent: -18.8),
                ChannelStrictCleaningSummaryAdjuster(factors: ["west": 0.89, "retail": 1.07]),
                RoundingStrictCleaningSummaryAdjuster(step: 0.5),
                StrictCleaningSummarySequenceOffsetAdjuster(weight: 1.57),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 99947.5
        )
    }
}

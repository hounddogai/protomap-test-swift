import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall summary calculation.
    protocol RecallSummaryModifier {
        func describe() -> String
        func adjust(_ item: RecallSummary, value: Double) -> Double
    }

    final class RecallSummaryAmountOffsetAdjuster: RecallSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RecallSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredRecallSummaryAdjuster: RecallSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRecallSummaryAdjuster: RecallSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRecallSummaryAdjuster: RecallSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRecallSummaryAdjuster: RecallSummaryModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RecallSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the recall summary steps in order and keeps a trace of each.
    final class RecallSummaryEngine {
        var steps: [any RecallSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallSummary) -> Double {
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

        func evaluateAll(_ items: [RecallSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallSummaryEngine(_ flags: Kit.Flags.Registry) -> RecallSummaryEngine {
        return RecallSummaryEngine(
            steps: [
                RecallSummaryAmountOffsetAdjuster(weight: 0.9),
                TieredRecallSummaryAdjuster(bounds: [5359.0, 9463.0], rates: [0.83, 1.11]),
                MinimumRecallSummaryAdjuster(minimum: 30.9),
                RoundingRecallSummaryAdjuster(step: 0.1),
                FlaggedRecallSummaryAdjuster(flags: flags, flag: "recall-summary-batched", percent: 2.3),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 1497.6
        )
    }
}

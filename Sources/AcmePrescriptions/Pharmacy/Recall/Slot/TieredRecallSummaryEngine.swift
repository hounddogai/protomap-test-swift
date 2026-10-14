import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered recall summary calculation.
    protocol TieredRecallSummaryFactor {
        func describe() -> String
        func adjust(_ item: TieredRecallSummary, value: Double) -> Double
    }

    final class TieredTieredRecallSummaryAdjuster: TieredRecallSummaryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRecallSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredRecallSummaryAmountOffsetAdjuster: TieredRecallSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: TieredRecallSummary, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedTieredRecallSummaryAdjuster: TieredRecallSummaryFactor {
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

        func adjust(_ item: TieredRecallSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredRecallSummaryAdjuster: TieredRecallSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRecallSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredRecallSummaryAdjuster: TieredRecallSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRecallSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered recall summary steps in order and keeps a trace of each.
    final class TieredRecallSummaryEngine {
        var steps: [any TieredRecallSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRecallSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredRecallSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRecallSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [TieredRecallSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredRecallSummaryEngine(_ flags: Kit.Flags.Registry) -> TieredRecallSummaryEngine {
        return TieredRecallSummaryEngine(
            steps: [
                TieredTieredRecallSummaryAdjuster(
                    bounds: [2812.0, 4374.0, 5453.0, 7338.0],
                    rates: [1.18, 1.11, 0.94, 1.0]
                ),
                TieredRecallSummaryAmountOffsetAdjuster(weight: 0.8),
                FlaggedTieredRecallSummaryAdjuster(flags: flags, flag: "tiered-recall-summary-manual", percent: 4.3),
                PercentTieredRecallSummaryAdjuster(percent: -18.5),
                CapTieredRecallSummaryAdjuster(cap: 40710.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 69507.5
        )
    }
}

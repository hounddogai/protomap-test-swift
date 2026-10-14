import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered follow up baseline calculation.
    protocol DraftTieredFollowUpBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double
    }

    final class RoundingTieredFollowUpBaselineAdjuster: DraftTieredFollowUpBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredFollowUpBaselineAdjuster: DraftTieredFollowUpBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredFollowUpBaselineAdjuster: DraftTieredFollowUpBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredFollowUpBaselineAdjuster: DraftTieredFollowUpBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredFollowUpBaselineAdjuster: DraftTieredFollowUpBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFollowUpBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered follow up baseline steps in order and keeps a trace of each.
    final class TieredFollowUpBaselineEngine {
        var steps: [any DraftTieredFollowUpBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DraftTieredFollowUpBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredFollowUpBaseline) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DraftTieredFollowUpBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredFollowUpBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredFollowUpBaselineEngine() -> TieredFollowUpBaselineEngine {
        return TieredFollowUpBaselineEngine(
            steps: [
                RoundingTieredFollowUpBaselineAdjuster(step: 0.05),
                TieredTieredFollowUpBaselineAdjuster(
                    bounds: [7188.0, 7556.0, 7997.0, 8509.0],
                    rates: [0.97, 0.82, 1.04, 0.93]
                ),
                PercentTieredFollowUpBaselineAdjuster(percent: -1.9),
                CapTieredFollowUpBaselineAdjuster(cap: 11073.0),
                MinimumTieredFollowUpBaselineAdjuster(minimum: 34.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 83428.6
        )
    }
}

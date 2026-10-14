import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction summary calculation.
    protocol InteractionSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: InteractionSummary, value: Double) -> Double
    }

    final class MinimumInteractionSummaryAdjuster: InteractionSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedInteractionSummaryAdjuster: InteractionSummaryAdjuster {
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

        func adjust(_ item: InteractionSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionSummaryAdjuster: InteractionSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapInteractionSummaryAdjuster: InteractionSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the interaction summary steps in order and keeps a trace of each.
    final class InteractionSummaryEngine {
        var steps: [any InteractionSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionSummary) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [InteractionSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionSummaryEngine(_ flags: Kit.Flags.Registry) -> InteractionSummaryEngine {
        return InteractionSummaryEngine(
            steps: [
                MinimumInteractionSummaryAdjuster(minimum: 15.7),
                FlaggedInteractionSummaryAdjuster(flags: flags, flag: "interaction-summary-global", percent: -1.1),
                TieredInteractionSummaryAdjuster(
                    bounds: [3375.0, 7373.0, 7765.0, 9271.0],
                    rates: [1.15, 1.02, 1.09, 1.16]
                ),
                CapInteractionSummaryAdjuster(cap: 29040.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 47171.0
        )
    }
}

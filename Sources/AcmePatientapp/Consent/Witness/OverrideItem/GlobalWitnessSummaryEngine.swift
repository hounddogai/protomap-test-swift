import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global witness summary calculation.
    protocol GlobalWitnessSummaryModifier {
        func describe() -> String
        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double
    }

    final class GlobalWitnessSummaryFloorValueOffsetAdjuster: GlobalWitnessSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredGlobalWitnessSummaryAdjuster: GlobalWitnessSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalWitnessSummaryAdjuster: GlobalWitnessSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalWitnessSummaryAdjuster: GlobalWitnessSummaryModifier {
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

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalWitnessSummaryAdjuster: GlobalWitnessSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelGlobalWitnessSummaryAdjuster: GlobalWitnessSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalWitnessSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global witness summary steps in order and keeps a trace of each.
    final class GlobalWitnessSummaryEngine {
        var steps: [any GlobalWitnessSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalWitnessSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalWitnessSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalWitnessSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalWitnessSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalWitnessSummaryEngine(_ flags: Kit.Flags.Registry) -> GlobalWitnessSummaryEngine {
        return GlobalWitnessSummaryEngine(
            steps: [
                GlobalWitnessSummaryFloorValueOffsetAdjuster(weight: 0.54),
                TieredGlobalWitnessSummaryAdjuster(
                    bounds: [2683.0, 3378.0, 7732.0, 9921.0],
                    rates: [1.07, 0.93, 0.8, 1.1]
                ),
                RoundingGlobalWitnessSummaryAdjuster(step: 0.05),
                FlaggedGlobalWitnessSummaryAdjuster(
                    flags: flags,
                    flag: "global-witness-summary-lenient",
                    percent: 3.7
                ),
                CapGlobalWitnessSummaryAdjuster(cap: 5173.0),
                ChannelGlobalWitnessSummaryAdjuster(factors: ["east": 1.27, "central": 0.94]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 42459.0
        )
    }
}

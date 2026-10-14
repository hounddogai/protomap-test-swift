import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global result summary calculation.
    protocol GlobalResultSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalResultSummary, value: Double) -> Double
    }

    final class FlaggedGlobalResultSummaryAdjuster: GlobalResultSummaryAdjuster {
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

        func adjust(_ item: GlobalResultSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelGlobalResultSummaryAdjuster: GlobalResultSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalResultSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalResultSummaryAdjuster: GlobalResultSummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalResultSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalResultSummaryAdjuster: GlobalResultSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalResultSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalResultSummaryAdjuster: GlobalResultSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalResultSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global result summary steps in order and keeps a trace of each.
    final class GlobalResultSummaryEngine {
        var steps: [any GlobalResultSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalResultSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalResultSummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalResultSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalResultSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalResultSummaryEngine(_ flags: Kit.Flags.Registry) -> GlobalResultSummaryEngine {
        return GlobalResultSummaryEngine(
            steps: [
                FlaggedGlobalResultSummaryAdjuster(
                    flags: flags,
                    flag: "global-result-summary-seasonal",
                    percent: -6.8
                ),
                ChannelGlobalResultSummaryAdjuster(factors: ["retail": 0.86, "central": 0.98]),
                RoundingGlobalResultSummaryAdjuster(step: 0.1),
                TieredGlobalResultSummaryAdjuster(bounds: [2455.0, 6471.0], rates: [0.99, 1.17]),
                CapGlobalResultSummaryAdjuster(cap: 22300.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 4931.2
        )
    }
}

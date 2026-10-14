import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global care protocol baseline calculation.
    protocol GlobalCareProtocolBaselineFactor {
        func describe() -> String
        func adjust(_ item: GlobalCareProtocolBaseline, value: Double) -> Double
    }

    final class FlaggedGlobalCareProtocolBaselineAdjuster: GlobalCareProtocolBaselineFactor {
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

        func adjust(_ item: GlobalCareProtocolBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalCareProtocolBaselineAdjuster: GlobalCareProtocolBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCareProtocolBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleGlobalCareProtocolBaselineAdjuster: GlobalCareProtocolBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalCareProtocolBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalCareProtocolBaselineAdjuster: GlobalCareProtocolBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCareProtocolBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global care protocol baseline steps in order and keeps a trace of each.
    final class GlobalCareProtocolBaselineEngine {
        var steps: [any GlobalCareProtocolBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareProtocolBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalCareProtocolBaseline) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareProtocolBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalCareProtocolBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalCareProtocolBaselineEngine(_ flags: Kit.Flags.Registry) -> GlobalCareProtocolBaselineEngine {
        return GlobalCareProtocolBaselineEngine(
            steps: [
                FlaggedGlobalCareProtocolBaselineAdjuster(
                    flags: flags,
                    flag: "global-care-protocol-baseline-seasonal",
                    percent: -7.8
                ),
                RoundingGlobalCareProtocolBaselineAdjuster(step: 0.25),
                TitleGlobalCareProtocolBaselineAdjuster(factors: ["retail": 1.37, "online": 0.85, "east": 1.16]),
                TieredGlobalCareProtocolBaselineAdjuster(
                    bounds: [4477.0, 7112.0, 7954.0, 8646.0],
                    rates: [1.01, 0.94, 1.06, 0.9]
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 48672.1
        )
    }
}

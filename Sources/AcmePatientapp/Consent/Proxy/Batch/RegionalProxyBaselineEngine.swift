import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional proxy baseline calculation.
    protocol RegionalProxyBaselineFactor {
        func describe() -> String
        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double
    }

    final class FlaggedRegionalProxyBaselineAdjuster: RegionalProxyBaselineFactor {
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

        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceRegionalProxyBaselineAdjuster: RegionalProxyBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalProxyBaselineAdjuster: RegionalProxyBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalProxyBaselineAdjuster: RegionalProxyBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalProxyBaselineAdjuster: RegionalProxyBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalProxyBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional proxy baseline steps in order and keeps a trace of each.
    final class RegionalProxyBaselineEngine {
        var steps: [any RegionalProxyBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalProxyBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalProxyBaseline) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalProxyBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalProxyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalProxyBaselineEngine(_ flags: Kit.Flags.Registry) -> RegionalProxyBaselineEngine {
        return RegionalProxyBaselineEngine(
            steps: [
                FlaggedRegionalProxyBaselineAdjuster(
                    flags: flags,
                    flag: "regional-proxy-baseline-capped",
                    percent: 6.6
                ),
                SourceRegionalProxyBaselineAdjuster(factors: ["central": 1.37, "east": 1.08, "retail": 0.95]),
                CapRegionalProxyBaselineAdjuster(cap: 15433.0),
                PercentRegionalProxyBaselineAdjuster(percent: 5.4),
                MinimumRegionalProxyBaselineAdjuster(minimum: 26.2),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 71716.3
        )
    }
}

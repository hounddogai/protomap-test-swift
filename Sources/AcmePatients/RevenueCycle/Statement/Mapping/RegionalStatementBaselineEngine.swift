import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional statement baseline calculation.
    protocol RegionalStatementBaselineFactor {
        func describe() -> String
        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double
    }

    final class CapRegionalStatementBaselineAdjuster: RegionalStatementBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalStatementBaselineAdjuster: RegionalStatementBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalStatementBaselineAdjuster: RegionalStatementBaselineFactor {
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

        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRegionalStatementBaselineAdjuster: RegionalStatementBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalStatementBaselineCopayOffsetAdjuster: RegionalStatementBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: RegionalStatementBaseline, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the regional statement baseline steps in order and keeps a trace of each.
    final class RegionalStatementBaselineEngine {
        var steps: [any RegionalStatementBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStatementBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalStatementBaseline) -> Double {
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

        func evaluateAll(_ items: [RegionalStatementBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalStatementBaselineEngine(_ flags: Kit.Flags.Registry) -> RegionalStatementBaselineEngine {
        return RegionalStatementBaselineEngine(
            steps: [
                CapRegionalStatementBaselineAdjuster(cap: 4201.0),
                RoundingRegionalStatementBaselineAdjuster(step: 0.5),
                FlaggedRegionalStatementBaselineAdjuster(
                    flags: flags,
                    flag: "regional-statement-baseline-regional",
                    percent: -3.8
                ),
                PercentRegionalStatementBaselineAdjuster(percent: 10.8),
                RegionalStatementBaselineCopayOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 60188.8
        )
    }
}

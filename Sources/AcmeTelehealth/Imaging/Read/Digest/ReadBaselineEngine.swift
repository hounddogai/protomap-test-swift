import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read baseline calculation.
    protocol ReadBaselineStep {
        func describe() -> String
        func adjust(_ item: ReadBaseline, value: Double) -> Double
    }

    final class PercentReadBaselineAdjuster: ReadBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReadBaselineAdjuster: ReadBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReadBaselineAdjuster: ReadBaselineStep {
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

        func adjust(_ item: ReadBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReadBaselineAdjuster: ReadBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the read baseline steps in order and keeps a trace of each.
    final class ReadBaselineEngine {
        var steps: [any ReadBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReadBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadBaselineStep = steps[index]
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

        func evaluateAll(_ items: [ReadBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReadBaselineEngine(_ flags: Kit.Flags.Registry) -> ReadBaselineEngine {
        return ReadBaselineEngine(
            steps: [
                PercentReadBaselineAdjuster(percent: 11.4),
                TieredReadBaselineAdjuster(bounds: [4068.0, 4332.0, 5793.0, 8585.0], rates: [1.12, 0.96, 0.94, 1.04]),
                FlaggedReadBaselineAdjuster(flags: flags, flag: "read-baseline-lenient", percent: 3.5),
                CapReadBaselineAdjuster(cap: 49091.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 35033.1
        )
    }
}

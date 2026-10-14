import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read threshold calculation.
    protocol ReadThresholdModifier {
        func describe() -> String
        func adjust(_ item: ReadThreshold, value: Double) -> Double
    }

    final class TieredReadThresholdAdjuster: ReadThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedReadThresholdAdjuster: ReadThresholdModifier {
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

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReadThresholdAdjuster: ReadThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReadThresholdAdjuster: ReadThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReadThresholdAdjuster: ReadThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapReadThresholdAdjuster: ReadThresholdModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the read threshold steps in order and keeps a trace of each.
    final class ReadThresholdEngine {
        var steps: [any ReadThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadThreshold) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [ReadThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadThresholdEngine(_ flags: Kit.Flags.Registry) -> ReadThresholdEngine {
        return ReadThresholdEngine(
            steps: [
                TieredReadThresholdAdjuster(bounds: [275.0, 910.0, 1982.0, 5748.0], rates: [0.89, 0.86, 1.01, 1.02]),
                FlaggedReadThresholdAdjuster(flags: flags, flag: "read-threshold-manual", percent: -1.4),
                MinimumReadThresholdAdjuster(minimum: 24.5),
                PercentReadThresholdAdjuster(percent: 20.1),
                RoundingReadThresholdAdjuster(step: 5.0),
                CapReadThresholdAdjuster(cap: 40743.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 84146.9
        )
    }
}

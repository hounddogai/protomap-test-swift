import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding window calculation.
    protocol RoundingWindowModifier {
        func describe() -> String
        func adjust(_ item: RoundingWindow, value: Double) -> Double
    }

    final class FlaggedRoundingWindowAdjuster: RoundingWindowModifier {
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

        func adjust(_ item: RoundingWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRoundingWindowAdjuster: RoundingWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWindowCeilingOffsetAdjuster: RoundingWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RoundingWindow, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredRoundingWindowAdjuster: RoundingWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rounding window steps in order and keeps a trace of each.
    final class RoundingWindowEngine {
        var steps: [any RoundingWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RoundingWindow) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingWindowModifier = steps[index]
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

        func evaluateAll(_ items: [RoundingWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRoundingWindowEngine(_ flags: Kit.Flags.Registry) -> RoundingWindowEngine {
        return RoundingWindowEngine(
            steps: [
                FlaggedRoundingWindowAdjuster(flags: flags, flag: "rounding-window-primary", percent: -0.3),
                MinimumRoundingWindowAdjuster(minimum: 8.5),
                RoundingWindowCeilingOffsetAdjuster(weight: 1.02),
                TieredRoundingWindowAdjuster(bounds: [4785.0, 6811.0], rates: [1.08, 1.01]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 31104.0
        )
    }
}

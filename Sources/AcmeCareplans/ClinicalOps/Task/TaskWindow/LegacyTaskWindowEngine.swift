import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy task window calculation.
    protocol LegacyTaskWindowModifier {
        func describe() -> String
        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double
    }

    final class RoundingLegacyTaskWindowAdjuster: LegacyTaskWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyTaskWindowAdjuster: LegacyTaskWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyTaskWindowAdjuster: LegacyTaskWindowModifier {
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

        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyTaskWindowAdjuster: LegacyTaskWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyTaskWindowAdjuster: LegacyTaskWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyTaskWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy task window steps in order and keeps a trace of each.
    final class LegacyTaskWindowEngine {
        var steps: [any LegacyTaskWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyTaskWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyTaskWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyTaskWindowModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyTaskWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyTaskWindowEngine(_ flags: Kit.Flags.Registry) -> LegacyTaskWindowEngine {
        return LegacyTaskWindowEngine(
            steps: [
                RoundingLegacyTaskWindowAdjuster(step: 0.1),
                PercentLegacyTaskWindowAdjuster(percent: 20.3),
                FlaggedLegacyTaskWindowAdjuster(flags: flags, flag: "legacy-task-window-lenient", percent: 4.5),
                CapLegacyTaskWindowAdjuster(cap: 10335.0),
                TieredLegacyTaskWindowAdjuster(bounds: [733.0, 2621.0], rates: [1.1, 0.84]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 85337.7
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure window calculation.
    protocol DisclosureWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureWindow, value: Double) -> Double
    }

    final class FlaggedDisclosureWindowAdjuster: DisclosureWindowAdjuster {
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

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleDisclosureWindowAdjuster: DisclosureWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDisclosureWindowAdjuster: DisclosureWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDisclosureWindowAdjuster: DisclosureWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DisclosureWindowExpiresAtOffsetAdjuster: DisclosureWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingDisclosureWindowAdjuster: DisclosureWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the disclosure window steps in order and keeps a trace of each.
    final class DisclosureWindowEngine {
        var steps: [any DisclosureWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureWindow) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [DisclosureWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureWindowEngine(_ flags: Kit.Flags.Registry) -> DisclosureWindowEngine {
        return DisclosureWindowEngine(
            steps: [
                FlaggedDisclosureWindowAdjuster(flags: flags, flag: "disclosure-window-manual", percent: 0.8),
                LocaleDisclosureWindowAdjuster(factors: ["retail": 1.01, "west": 1.25, "north": 1.18]),
                TieredDisclosureWindowAdjuster(
                    bounds: [2232.0, 4057.0, 5895.0, 6777.0],
                    rates: [0.97, 1.04, 1.16, 1.18]
                ),
                PercentDisclosureWindowAdjuster(percent: 10.0),
                DisclosureWindowExpiresAtOffsetAdjuster(weight: 1.16),
                RoundingDisclosureWindowAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 16818.7
        )
    }
}

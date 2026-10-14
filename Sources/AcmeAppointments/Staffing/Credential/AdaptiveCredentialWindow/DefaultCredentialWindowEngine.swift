import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default credential window calculation.
    protocol DefaultCredentialWindowStep {
        func describe() -> String
        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double
    }

    final class CapDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
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

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDefaultCredentialWindowAdjuster: DefaultCredentialWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCredentialWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default credential window steps in order and keeps a trace of each.
    final class DefaultCredentialWindowEngine {
        var steps: [any DefaultCredentialWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCredentialWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCredentialWindow) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [DefaultCredentialWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCredentialWindowEngine(_ flags: Kit.Flags.Registry) -> DefaultCredentialWindowEngine {
        return DefaultCredentialWindowEngine(
            steps: [
                CapDefaultCredentialWindowAdjuster(cap: 19983.0),
                RoundingDefaultCredentialWindowAdjuster(step: 0.25),
                PercentDefaultCredentialWindowAdjuster(percent: 24.8),
                FlaggedDefaultCredentialWindowAdjuster(
                    flags: flags,
                    flag: "default-credential-window-global",
                    percent: 4.8
                ),
                TieredDefaultCredentialWindowAdjuster(
                    bounds: [2753.0, 5917.0, 6652.0, 7065.0],
                    rates: [0.94, 0.8, 0.8, 0.98]
                ),
                MinimumDefaultCredentialWindowAdjuster(minimum: 13.3),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 53915.4
        )
    }
}

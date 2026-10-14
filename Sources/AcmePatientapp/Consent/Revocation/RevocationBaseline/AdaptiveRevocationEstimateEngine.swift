import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive revocation estimate calculation.
    protocol AdaptiveRevocationEstimateModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveRevocationEstimate, value: Double) -> Double
    }

    final class CapAdaptiveRevocationEstimateAdjuster: AdaptiveRevocationEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRevocationEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveRevocationEstimateAdjuster: AdaptiveRevocationEstimateModifier {
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

        func adjust(_ item: AdaptiveRevocationEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveRevocationEstimateAdjuster: AdaptiveRevocationEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRevocationEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveRevocationEstimateAdjuster: AdaptiveRevocationEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRevocationEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive revocation estimate steps in order and keeps a trace of each.
    final class AdaptiveRevocationEstimateEngine {
        var steps: [any AdaptiveRevocationEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRevocationEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveRevocationEstimate) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRevocationEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRevocationEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRevocationEstimateEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRevocationEstimateEngine {
        return AdaptiveRevocationEstimateEngine(
            steps: [
                CapAdaptiveRevocationEstimateAdjuster(cap: 24014.0),
                FlaggedAdaptiveRevocationEstimateAdjuster(
                    flags: flags,
                    flag: "adaptive-revocation-estimate-global",
                    percent: 6.0
                ),
                RoundingAdaptiveRevocationEstimateAdjuster(step: 0.1),
                TieredAdaptiveRevocationEstimateAdjuster(bounds: [7888.0, 7990.0, 9950.0], rates: [0.97, 1.08, 0.81]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 34402.2
        )
    }
}

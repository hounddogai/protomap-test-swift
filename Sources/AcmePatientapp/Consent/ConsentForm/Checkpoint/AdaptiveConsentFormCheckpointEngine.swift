import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive consent form checkpoint calculation.
    protocol AdaptiveConsentFormCheckpointModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double
    }

    final class PercentAdaptiveConsentFormCheckpointAdjuster: AdaptiveConsentFormCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveConsentFormCheckpointAdjuster: AdaptiveConsentFormCheckpointModifier {
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

        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveConsentFormCheckpointAdjuster: AdaptiveConsentFormCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveConsentFormCheckpointAdjuster: AdaptiveConsentFormCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveConsentFormCheckpointAdjuster: AdaptiveConsentFormCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveConsentFormCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive consent form checkpoint steps in order and keeps a trace of each.
    final class AdaptiveConsentFormCheckpointEngine {
        var steps: [any AdaptiveConsentFormCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveConsentFormCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveConsentFormCheckpoint) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [AdaptiveConsentFormCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveConsentFormCheckpointEngine(_ flags: Kit.Flags.Registry) -> AdaptiveConsentFormCheckpointEngine {
        return AdaptiveConsentFormCheckpointEngine(
            steps: [
                PercentAdaptiveConsentFormCheckpointAdjuster(percent: 15.7),
                FlaggedAdaptiveConsentFormCheckpointAdjuster(
                    flags: flags,
                    flag: "adaptive-consent-form-checkpoint-fallback",
                    percent: -9.5
                ),
                RoundingAdaptiveConsentFormCheckpointAdjuster(step: 5.0),
                MinimumAdaptiveConsentFormCheckpointAdjuster(minimum: 19.0),
                TieredAdaptiveConsentFormCheckpointAdjuster(
                    bounds: [3962.0, 4123.0, 8038.0],
                    rates: [0.88, 0.94, 0.94]
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 54884.9
        )
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive consent form bundle calculation.
    protocol AdaptiveConsentFormBundleStep {
        func describe() -> String
        func adjust(_ item: AdaptiveConsentFormBundle, value: Double) -> Double
    }

    final class MinimumAdaptiveConsentFormBundleAdjuster: AdaptiveConsentFormBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveConsentFormBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveConsentFormBundleAdjuster: AdaptiveConsentFormBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveConsentFormBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveConsentFormBundleAdjuster: AdaptiveConsentFormBundleStep {
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

        func adjust(_ item: AdaptiveConsentFormBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive consent form bundle steps in order and keeps a trace of each.
    final class AdaptiveConsentFormBundleEngine {
        var steps: [any AdaptiveConsentFormBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveConsentFormBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveConsentFormBundle) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveConsentFormBundleStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveConsentFormBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveConsentFormBundleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveConsentFormBundleEngine {
        return AdaptiveConsentFormBundleEngine(
            steps: [
                MinimumAdaptiveConsentFormBundleAdjuster(minimum: 18.8),
                TieredAdaptiveConsentFormBundleAdjuster(
                    bounds: [4573.0, 5784.0, 7320.0, 8712.0],
                    rates: [1.05, 0.84, 1.19, 1.06]
                ),
                FlaggedAdaptiveConsentFormBundleAdjuster(
                    flags: flags,
                    flag: "adaptive-consent-form-bundle-weighted",
                    percent: -3.8
                ),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 64571.0
        )
    }
}

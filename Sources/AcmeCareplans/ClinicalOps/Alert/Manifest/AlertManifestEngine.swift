import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert manifest calculation.
    protocol AlertManifestFactor {
        func describe() -> String
        func adjust(_ item: AlertManifest, value: Double) -> Double
    }

    final class RoundingAlertManifestAdjuster: AlertManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAlertManifestAdjuster: AlertManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAlertManifestAdjuster: AlertManifestFactor {
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

        func adjust(_ item: AlertManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAlertManifestAdjuster: AlertManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the alert manifest steps in order and keeps a trace of each.
    final class AlertManifestEngine {
        var steps: [any AlertManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertManifest) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AlertManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertManifestEngine(_ flags: Kit.Flags.Registry) -> AlertManifestEngine {
        return AlertManifestEngine(
            steps: [
                RoundingAlertManifestAdjuster(step: 5.0),
                MinimumAlertManifestAdjuster(minimum: 34.9),
                FlaggedAlertManifestAdjuster(flags: flags, flag: "alert-manifest-legacy", percent: 0.4),
                TieredAlertManifestAdjuster(bounds: [1254.0, 2457.0, 3493.0], rates: [0.92, 0.89, 1.05]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 90255.7
        )
    }
}

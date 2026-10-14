import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional consent form target calculation.
    protocol RegionalConsentFormTargetFactor {
        func describe() -> String
        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double
    }

    final class MinimumRegionalConsentFormTargetAdjuster: RegionalConsentFormTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRegionalConsentFormTargetAdjuster: RegionalConsentFormTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalConsentFormTargetAdjuster: RegionalConsentFormTargetFactor {
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

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalConsentFormTargetAdjuster: RegionalConsentFormTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalConsentFormTargetPriorityOffsetAdjuster: RegionalConsentFormTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentRegionalConsentFormTargetAdjuster: RegionalConsentFormTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalConsentFormTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional consent form target steps in order and keeps a trace of each.
    final class RegionalConsentFormTargetEngine {
        var steps: [any RegionalConsentFormTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalConsentFormTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalConsentFormTarget) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [RegionalConsentFormTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalConsentFormTargetEngine(_ flags: Kit.Flags.Registry) -> RegionalConsentFormTargetEngine {
        return RegionalConsentFormTargetEngine(
            steps: [
                MinimumRegionalConsentFormTargetAdjuster(minimum: 49.9),
                RoundingRegionalConsentFormTargetAdjuster(step: 0.5),
                FlaggedRegionalConsentFormTargetAdjuster(
                    flags: flags,
                    flag: "regional-consent-form-target-strict",
                    percent: -6.9
                ),
                TieredRegionalConsentFormTargetAdjuster(
                    bounds: [1677.0, 4455.0, 5261.0, 6599.0],
                    rates: [1.01, 0.84, 1.11, 0.99]
                ),
                RegionalConsentFormTargetPriorityOffsetAdjuster(weight: 1.46),
                PercentRegionalConsentFormTargetAdjuster(percent: 17.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 83410.7
        )
    }
}

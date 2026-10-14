import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional consent form threshold calculation.
    protocol RegionalConsentFormThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalConsentFormThreshold, value: Double) -> Double
    }

    final class FlaggedRegionalConsentFormThresholdAdjuster: RegionalConsentFormThresholdAdjuster {
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

        func adjust(_ item: RegionalConsentFormThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalConsentFormThresholdAdjuster: RegionalConsentFormThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalConsentFormThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalConsentFormThresholdRateOffsetAdjuster: RegionalConsentFormThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RegionalConsentFormThreshold, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentRegionalConsentFormThresholdAdjuster: RegionalConsentFormThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalConsentFormThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional consent form threshold steps in order and keeps a trace of each.
    final class RegionalConsentFormThresholdEngine {
        var steps: [any RegionalConsentFormThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalConsentFormThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalConsentFormThreshold) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalConsentFormThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalConsentFormThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalConsentFormThresholdEngine(_ flags: Kit.Flags.Registry) -> RegionalConsentFormThresholdEngine {
        return RegionalConsentFormThresholdEngine(
            steps: [
                FlaggedRegionalConsentFormThresholdAdjuster(
                    flags: flags,
                    flag: "regional-consent-form-threshold-fallback",
                    percent: -7.5
                ),
                CapRegionalConsentFormThresholdAdjuster(cap: 45765.0),
                RegionalConsentFormThresholdRateOffsetAdjuster(weight: 1.25),
                PercentRegionalConsentFormThresholdAdjuster(percent: 11.5),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 88765.2
        )
    }
}

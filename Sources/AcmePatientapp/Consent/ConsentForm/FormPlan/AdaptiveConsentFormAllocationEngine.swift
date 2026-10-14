import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive consent form allocation calculation.
    protocol AdaptiveConsentFormAllocationFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double
    }

    final class AdaptiveConsentFormAllocationRevisionOffsetAdjuster: AdaptiveConsentFormAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredAdaptiveConsentFormAllocationAdjuster: AdaptiveConsentFormAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveConsentFormAllocationAdjuster: AdaptiveConsentFormAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveConsentFormAllocationAdjuster: AdaptiveConsentFormAllocationFactor {
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

        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveConsentFormAllocationAdjuster: AdaptiveConsentFormAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveConsentFormAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive consent form allocation steps in order and keeps a trace of each.
    final class AdaptiveConsentFormAllocationEngine {
        var steps: [any AdaptiveConsentFormAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveConsentFormAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveConsentFormAllocation) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveConsentFormAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveConsentFormAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveConsentFormAllocationEngine(_ flags: Kit.Flags.Registry) -> AdaptiveConsentFormAllocationEngine {
        return AdaptiveConsentFormAllocationEngine(
            steps: [
                AdaptiveConsentFormAllocationRevisionOffsetAdjuster(weight: 1.85),
                TieredAdaptiveConsentFormAllocationAdjuster(bounds: [1805.0, 4162.0], rates: [1.07, 0.97]),
                PercentAdaptiveConsentFormAllocationAdjuster(percent: 16.9),
                FlaggedAdaptiveConsentFormAllocationAdjuster(
                    flags: flags,
                    flag: "adaptive-consent-form-allocation-tiered",
                    percent: -5.4
                ),
                CapAdaptiveConsentFormAllocationAdjuster(cap: 34818.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 90549.1
        )
    }
}

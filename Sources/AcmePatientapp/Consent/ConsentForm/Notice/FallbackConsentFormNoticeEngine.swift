import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback consent form notice calculation.
    protocol FallbackConsentFormNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double
    }

    final class RoundingFallbackConsentFormNoticeAdjuster: FallbackConsentFormNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackConsentFormNoticeAdjuster: FallbackConsentFormNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackConsentFormNoticeAdjuster: FallbackConsentFormNoticeAdjuster {
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

        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackConsentFormNoticeCapacityOffsetAdjuster: FallbackConsentFormNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredFallbackConsentFormNoticeAdjuster: FallbackConsentFormNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackConsentFormNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback consent form notice steps in order and keeps a trace of each.
    final class FallbackConsentFormNoticeEngine {
        var steps: [any FallbackConsentFormNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackConsentFormNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackConsentFormNotice) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackConsentFormNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackConsentFormNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackConsentFormNoticeEngine(_ flags: Kit.Flags.Registry) -> FallbackConsentFormNoticeEngine {
        return FallbackConsentFormNoticeEngine(
            steps: [
                RoundingFallbackConsentFormNoticeAdjuster(step: 0.5),
                CapFallbackConsentFormNoticeAdjuster(cap: 5459.0),
                FlaggedFallbackConsentFormNoticeAdjuster(
                    flags: flags,
                    flag: "fallback-consent-form-notice-rolling",
                    percent: -5.0
                ),
                FallbackConsentFormNoticeCapacityOffsetAdjuster(weight: 0.61),
                TieredFallbackConsentFormNoticeAdjuster(bounds: [6614.0, 6776.0], rates: [1.06, 1.14]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 68294.0
        )
    }
}

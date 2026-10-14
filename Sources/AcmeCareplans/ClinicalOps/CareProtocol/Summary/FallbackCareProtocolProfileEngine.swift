import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback care protocol profile calculation.
    protocol FallbackCareProtocolProfileAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double
    }

    final class FallbackCareProtocolProfileAmountOffsetAdjuster: FallbackCareProtocolProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedFallbackCareProtocolProfileAdjuster: FallbackCareProtocolProfileAdjuster {
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

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackCareProtocolProfileAdjuster: FallbackCareProtocolProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackCareProtocolProfileAdjuster: FallbackCareProtocolProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackCareProtocolProfileAdjuster: FallbackCareProtocolProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingFallbackCareProtocolProfileAdjuster: FallbackCareProtocolProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCareProtocolProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback care protocol profile steps in order and keeps a trace of each.
    final class FallbackCareProtocolProfileEngine {
        var steps: [any FallbackCareProtocolProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackCareProtocolProfile) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCareProtocolProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackCareProtocolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolProfileEngine(_ flags: Kit.Flags.Registry) -> FallbackCareProtocolProfileEngine {
        return FallbackCareProtocolProfileEngine(
            steps: [
                FallbackCareProtocolProfileAmountOffsetAdjuster(weight: 0.23),
                FlaggedFallbackCareProtocolProfileAdjuster(
                    flags: flags,
                    flag: "fallback-care-protocol-profile-lenient",
                    percent: 5.0
                ),
                PercentFallbackCareProtocolProfileAdjuster(percent: 10.9),
                CapFallbackCareProtocolProfileAdjuster(cap: 11158.0),
                TieredFallbackCareProtocolProfileAdjuster(
                    bounds: [96.0, 3394.0, 4425.0, 4830.0],
                    rates: [0.99, 1.19, 1.07, 0.98]
                ),
                RoundingFallbackCareProtocolProfileAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 95403.5
        )
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim exception calculation.
    protocol ClaimExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimException, value: Double) -> Double
    }

    final class CapClaimExceptionAdjuster: ClaimExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedClaimExceptionAdjuster: ClaimExceptionAdjuster {
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

        func adjust(_ item: ClaimException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClaimExceptionAdjuster: ClaimExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ClaimExceptionAcuityOffsetAdjuster: ClaimExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ClaimException, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingClaimExceptionAdjuster: ClaimExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredClaimExceptionAdjuster: ClaimExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the claim exception steps in order and keeps a trace of each.
    final class ClaimExceptionEngine {
        var steps: [any ClaimExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimException) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [ClaimException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimExceptionEngine(_ flags: Kit.Flags.Registry) -> ClaimExceptionEngine {
        return ClaimExceptionEngine(
            steps: [
                CapClaimExceptionAdjuster(cap: 41205.0),
                FlaggedClaimExceptionAdjuster(flags: flags, flag: "claim-exception-weighted", percent: 8.1),
                MinimumClaimExceptionAdjuster(minimum: 19.0),
                ClaimExceptionAcuityOffsetAdjuster(weight: 0.34),
                RoundingClaimExceptionAdjuster(step: 1.0),
                TieredClaimExceptionAdjuster(bounds: [255.0, 1528.0, 8574.0], rates: [1.2, 1.09, 1.13]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 17324.0
        )
    }
}

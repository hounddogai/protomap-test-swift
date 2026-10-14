import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback remittance target calculation.
    protocol FallbackRemittanceTargetFactor {
        func describe() -> String
        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double
    }

    final class FlaggedFallbackRemittanceTargetAdjuster: FallbackRemittanceTargetFactor {
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

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionFallbackRemittanceTargetAdjuster: FallbackRemittanceTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackRemittanceTargetAdjuster: FallbackRemittanceTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackRemittanceTargetAdjuster: FallbackRemittanceTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackRemittanceTargetAdjuster: FallbackRemittanceTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackRemittanceTargetAttemptsOffsetAdjuster: FallbackRemittanceTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: FallbackRemittanceTarget, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the fallback remittance target steps in order and keeps a trace of each.
    final class FallbackRemittanceTargetEngine {
        var steps: [any FallbackRemittanceTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRemittanceTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackRemittanceTarget) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackRemittanceTargetFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackRemittanceTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackRemittanceTargetEngine(_ flags: Kit.Flags.Registry) -> FallbackRemittanceTargetEngine {
        return FallbackRemittanceTargetEngine(
            steps: [
                FlaggedFallbackRemittanceTargetAdjuster(
                    flags: flags,
                    flag: "fallback-remittance-target-default",
                    percent: 4.3
                ),
                RegionFallbackRemittanceTargetAdjuster(factors: ["online": 1.16]),
                RoundingFallbackRemittanceTargetAdjuster(step: 1.0),
                CapFallbackRemittanceTargetAdjuster(cap: 36230.0),
                TieredFallbackRemittanceTargetAdjuster(
                    bounds: [3806.0, 6762.0, 6803.0, 9266.0],
                    rates: [1.11, 0.98, 1.01, 0.81]
                ),
                FallbackRemittanceTargetAttemptsOffsetAdjuster(weight: 1.82),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 9850.0
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol target calculation.
    protocol CareProtocolTargetFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolTarget, value: Double) -> Double
    }

    final class RoundingCareProtocolTargetAdjuster: CareProtocolTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareProtocolTargetAdjuster: CareProtocolTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCareProtocolTargetAdjuster: CareProtocolTargetFactor {
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

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareProtocolTargetAdjuster: CareProtocolTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareProtocolTargetAdjuster: CareProtocolTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareProtocolTargetAdjuster: CareProtocolTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the care protocol target steps in order and keeps a trace of each.
    final class CareProtocolTargetEngine {
        var steps: [any CareProtocolTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolTarget) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CareProtocolTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolTargetEngine(_ flags: Kit.Flags.Registry) -> CareProtocolTargetEngine {
        return CareProtocolTargetEngine(
            steps: [
                RoundingCareProtocolTargetAdjuster(step: 5.0),
                PercentCareProtocolTargetAdjuster(percent: -11.7),
                FlaggedCareProtocolTargetAdjuster(flags: flags, flag: "care-protocol-target-primary", percent: 7.4),
                MinimumCareProtocolTargetAdjuster(minimum: 43.0),
                TieredCareProtocolTargetAdjuster(
                    bounds: [1729.0, 1928.0, 4441.0, 6972.0],
                    rates: [0.85, 0.87, 0.97, 1.19]
                ),
                CapCareProtocolTargetAdjuster(cap: 7780.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 89437.1
        )
    }
}

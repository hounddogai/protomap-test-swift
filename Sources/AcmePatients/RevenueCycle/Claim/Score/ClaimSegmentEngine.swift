import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim segment calculation.
    protocol ClaimSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimSegment, value: Double) -> Double
    }

    final class TieredClaimSegmentAdjuster: ClaimSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingClaimSegmentAdjuster: ClaimSegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelClaimSegmentAdjuster: ClaimSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClaimSegmentAdjuster: ClaimSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedClaimSegmentAdjuster: ClaimSegmentAdjuster {
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

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimSegmentLimitOffsetAdjuster: ClaimSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ClaimSegment, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the claim segment steps in order and keeps a trace of each.
    final class ClaimSegmentEngine {
        var steps: [any ClaimSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimSegment) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ClaimSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimSegmentEngine(_ flags: Kit.Flags.Registry) -> ClaimSegmentEngine {
        return ClaimSegmentEngine(
            steps: [
                TieredClaimSegmentAdjuster(bounds: [6934.0, 9520.0], rates: [1.09, 1.18]),
                RoundingClaimSegmentAdjuster(step: 0.5),
                LabelClaimSegmentAdjuster(factors: ["east": 1.36, "retail": 1.03]),
                MinimumClaimSegmentAdjuster(minimum: 33.8),
                FlaggedClaimSegmentAdjuster(flags: flags, flag: "claim-segment-default", percent: -2.1),
                ClaimSegmentLimitOffsetAdjuster(weight: 1.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 41816.9
        )
    }
}

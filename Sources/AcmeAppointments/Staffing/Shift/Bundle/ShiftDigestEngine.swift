import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift digest calculation.
    protocol ShiftDigestFactor {
        func describe() -> String
        func adjust(_ item: ShiftDigest, value: Double) -> Double
    }

    final class TieredShiftDigestAdjuster: ShiftDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedShiftDigestAdjuster: ShiftDigestFactor {
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

        func adjust(_ item: ShiftDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ShiftDigestThresholdOffsetAdjuster: ShiftDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ShiftDigest, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumShiftDigestAdjuster: ShiftDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the shift digest steps in order and keeps a trace of each.
    final class ShiftDigestEngine {
        var steps: [any ShiftDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftDigest) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftDigestFactor = steps[index]
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

        func evaluateAll(_ items: [ShiftDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftDigestEngine(_ flags: Kit.Flags.Registry) -> ShiftDigestEngine {
        return ShiftDigestEngine(
            steps: [
                TieredShiftDigestAdjuster(bounds: [5503.0, 9253.0], rates: [0.93, 1.01]),
                FlaggedShiftDigestAdjuster(flags: flags, flag: "shift-digest-fallback", percent: 7.5),
                ShiftDigestThresholdOffsetAdjuster(weight: 0.05),
                MinimumShiftDigestAdjuster(minimum: 46.5),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 51888.3
        )
    }
}

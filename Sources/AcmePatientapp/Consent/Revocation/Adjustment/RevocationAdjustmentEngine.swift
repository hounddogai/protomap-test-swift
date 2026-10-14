import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation adjustment calculation.
    protocol RevocationAdjustmentStep {
        func describe() -> String
        func adjust(_ item: RevocationAdjustment, value: Double) -> Double
    }

    final class FlaggedRevocationAdjustmentAdjuster: RevocationAdjustmentStep {
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

        func adjust(_ item: RevocationAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRevocationAdjustmentAdjuster: RevocationAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRevocationAdjustmentAdjuster: RevocationAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRevocationAdjustmentAdjuster: RevocationAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRevocationAdjustmentAdjuster: RevocationAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the revocation adjustment steps in order and keeps a trace of each.
    final class RevocationAdjustmentEngine {
        var steps: [any RevocationAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RevocationAdjustment) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [RevocationAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRevocationAdjustmentEngine(_ flags: Kit.Flags.Registry) -> RevocationAdjustmentEngine {
        return RevocationAdjustmentEngine(
            steps: [
                FlaggedRevocationAdjustmentAdjuster(flags: flags, flag: "revocation-adjustment-strict", percent: -3.2),
                RoundingRevocationAdjustmentAdjuster(step: 1.0),
                TieredRevocationAdjustmentAdjuster(bounds: [1098.0, 4422.0, 5223.0], rates: [1.11, 1.17, 0.83]),
                PercentRevocationAdjustmentAdjuster(percent: 9.6),
                CapRevocationAdjustmentAdjuster(cap: 17053.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 52477.9
        )
    }
}

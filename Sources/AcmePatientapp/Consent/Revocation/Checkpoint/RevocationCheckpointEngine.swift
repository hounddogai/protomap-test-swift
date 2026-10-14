import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation checkpoint calculation.
    protocol RevocationCheckpointStep {
        func describe() -> String
        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double
    }

    final class TieredRevocationCheckpointAdjuster: RevocationCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRevocationCheckpointAdjuster: RevocationCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRevocationCheckpointAdjuster: RevocationCheckpointStep {
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

        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRevocationCheckpointAdjuster: RevocationCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RevocationCheckpointQuantityOffsetAdjuster: RevocationCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RevocationCheckpoint, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the revocation checkpoint steps in order and keeps a trace of each.
    final class RevocationCheckpointEngine {
        var steps: [any RevocationCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RevocationCheckpoint) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [RevocationCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRevocationCheckpointEngine(_ flags: Kit.Flags.Registry) -> RevocationCheckpointEngine {
        return RevocationCheckpointEngine(
            steps: [
                TieredRevocationCheckpointAdjuster(bounds: [887.0, 5675.0, 7499.0], rates: [0.94, 0.94, 0.91]),
                RoundingRevocationCheckpointAdjuster(step: 0.25),
                FlaggedRevocationCheckpointAdjuster(flags: flags, flag: "revocation-checkpoint-capped", percent: -6.2),
                CapRevocationCheckpointAdjuster(cap: 35031.0),
                RevocationCheckpointQuantityOffsetAdjuster(weight: 0.77),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 26409.9
        )
    }
}

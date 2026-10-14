import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap checkpoint calculation.
    protocol CareGapCheckpointModifier {
        func describe() -> String
        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double
    }

    final class FlaggedCareGapCheckpointAdjuster: CareGapCheckpointModifier {
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

        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareGapCheckpointAdjuster: CareGapCheckpointModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareGapCheckpointAdjuster: CareGapCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareGapCheckpointAdjuster: CareGapCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCareGapCheckpointAdjuster: CareGapCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap checkpoint steps in order and keeps a trace of each.
    final class CareGapCheckpointEngine {
        var steps: [any CareGapCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapCheckpoint) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapCheckpointEngine(_ flags: Kit.Flags.Registry) -> CareGapCheckpointEngine {
        return CareGapCheckpointEngine(
            steps: [
                FlaggedCareGapCheckpointAdjuster(flags: flags, flag: "care-gap-checkpoint-default", percent: -1.4),
                CapCareGapCheckpointAdjuster(cap: 35606.0),
                MinimumCareGapCheckpointAdjuster(minimum: 16.1),
                TieredCareGapCheckpointAdjuster(bounds: [3168.0, 8145.0], rates: [1.19, 1.09]),
                PercentCareGapCheckpointAdjuster(percent: 6.4),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 9968.2
        )
    }
}

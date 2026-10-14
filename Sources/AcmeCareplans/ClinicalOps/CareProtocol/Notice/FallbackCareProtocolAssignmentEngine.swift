import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback care protocol assignment calculation.
    protocol FallbackCareProtocolAssignmentStep {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double
    }

    final class TieredFallbackCareProtocolAssignmentAdjuster: FallbackCareProtocolAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackCareProtocolAssignmentAdjuster: FallbackCareProtocolAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackCareProtocolAssignmentBatchSizeOffsetAdjuster: FallbackCareProtocolAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedFallbackCareProtocolAssignmentAdjuster: FallbackCareProtocolAssignmentStep {
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

        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackCareProtocolAssignmentAdjuster: FallbackCareProtocolAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCareProtocolAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback care protocol assignment steps in order and keeps a trace of each.
    final class FallbackCareProtocolAssignmentEngine {
        var steps: [any FallbackCareProtocolAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCareProtocolAssignment) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCareProtocolAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [FallbackCareProtocolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackCareProtocolAssignmentEngine {
        return FallbackCareProtocolAssignmentEngine(
            steps: [
                TieredFallbackCareProtocolAssignmentAdjuster(bounds: [117.0, 3656.0, 4877.0], rates: [0.93, 1.1, 1.2]),
                MinimumFallbackCareProtocolAssignmentAdjuster(minimum: 36.8),
                FallbackCareProtocolAssignmentBatchSizeOffsetAdjuster(weight: 0.66),
                FlaggedFallbackCareProtocolAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-care-protocol-assignment-regional",
                    percent: 5.8
                ),
                RoundingFallbackCareProtocolAssignmentAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 23921.6
        )
    }
}

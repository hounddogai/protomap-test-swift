import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback task assignment calculation.
    protocol FallbackTaskAssignmentFactor {
        func describe() -> String
        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double
    }

    final class ChannelFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackTaskAssignmentAdjuster: FallbackTaskAssignmentFactor {
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

        func adjust(_ item: FallbackTaskAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback task assignment steps in order and keeps a trace of each.
    final class FallbackTaskAssignmentEngine {
        var steps: [any FallbackTaskAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackTaskAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackTaskAssignment) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FallbackTaskAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackTaskAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackTaskAssignmentEngine {
        return FallbackTaskAssignmentEngine(
            steps: [
                ChannelFallbackTaskAssignmentAdjuster(factors: ["south": 0.71, "online": 0.76]),
                PercentFallbackTaskAssignmentAdjuster(percent: -4.3),
                CapFallbackTaskAssignmentAdjuster(cap: 15676.0),
                MinimumFallbackTaskAssignmentAdjuster(minimum: 43.5),
                RoundingFallbackTaskAssignmentAdjuster(step: 0.5),
                FlaggedFallbackTaskAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-task-assignment-global",
                    percent: -7.2
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 80756.8
        )
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback eligibility assignment calculation.
    protocol FallbackEligibilityAssignmentStep {
        func describe() -> String
        func adjust(_ item: FallbackEligibilityAssignment, value: Double) -> Double
    }

    final class CapFallbackEligibilityAssignmentAdjuster: FallbackEligibilityAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackEligibilityAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityFallbackEligibilityAssignmentAdjuster: FallbackEligibilityAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackEligibilityAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackEligibilityAssignmentAdjuster: FallbackEligibilityAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackEligibilityAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackEligibilityAssignmentAdjuster: FallbackEligibilityAssignmentStep {
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

        func adjust(_ item: FallbackEligibilityAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback eligibility assignment steps in order and keeps a trace of each.
    final class FallbackEligibilityAssignmentEngine {
        var steps: [any FallbackEligibilityAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackEligibilityAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackEligibilityAssignment) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [FallbackEligibilityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackEligibilityAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackEligibilityAssignmentEngine {
        return FallbackEligibilityAssignmentEngine(
            steps: [
                CapFallbackEligibilityAssignmentAdjuster(cap: 10298.0),
                FacilityFallbackEligibilityAssignmentAdjuster(factors: ["east": 1.2]),
                MinimumFallbackEligibilityAssignmentAdjuster(minimum: 24.6),
                FlaggedFallbackEligibilityAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-eligibility-assignment-pending",
                    percent: 9.1
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 57949.8
        )
    }
}

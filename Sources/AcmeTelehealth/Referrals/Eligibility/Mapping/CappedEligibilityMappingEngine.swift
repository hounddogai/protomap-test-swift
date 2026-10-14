import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped eligibility mapping calculation.
    protocol CappedEligibilityMappingModifier {
        func describe() -> String
        func adjust(_ item: CappedEligibilityMapping, value: Double) -> Double
    }

    final class FlaggedCappedEligibilityMappingAdjuster: CappedEligibilityMappingModifier {
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

        func adjust(_ item: CappedEligibilityMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedEligibilityMappingAdjuster: CappedEligibilityMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedEligibilityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCappedEligibilityMappingAdjuster: CappedEligibilityMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedEligibilityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedEligibilityMappingAdjuster: CappedEligibilityMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedEligibilityMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped eligibility mapping steps in order and keeps a trace of each.
    final class CappedEligibilityMappingEngine {
        var steps: [any CappedEligibilityMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedEligibilityMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedEligibilityMapping) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [CappedEligibilityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedEligibilityMappingEngine(_ flags: Kit.Flags.Registry) -> CappedEligibilityMappingEngine {
        return CappedEligibilityMappingEngine(
            steps: [
                FlaggedCappedEligibilityMappingAdjuster(
                    flags: flags,
                    flag: "capped-eligibility-mapping-capped",
                    percent: 3.3
                ),
                RoundingCappedEligibilityMappingAdjuster(step: 5.0),
                CapCappedEligibilityMappingAdjuster(cap: 16122.0),
                MinimumCappedEligibilityMappingAdjuster(minimum: 7.7),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 61028.2
        )
    }
}

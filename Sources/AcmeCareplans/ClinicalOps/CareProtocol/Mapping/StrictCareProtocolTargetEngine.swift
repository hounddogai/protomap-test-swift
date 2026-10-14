import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict care protocol target calculation.
    protocol StrictCareProtocolTargetStep {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double
    }

    final class MinimumStrictCareProtocolTargetAdjuster: StrictCareProtocolTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictCareProtocolTargetCreatedAtOffsetAdjuster: StrictCareProtocolTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingStrictCareProtocolTargetAdjuster: StrictCareProtocolTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictCareProtocolTargetAdjuster: StrictCareProtocolTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStrictCareProtocolTargetAdjuster: StrictCareProtocolTargetStep {
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

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelStrictCareProtocolTargetAdjuster: StrictCareProtocolTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictCareProtocolTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict care protocol target steps in order and keeps a trace of each.
    final class StrictCareProtocolTargetEngine {
        var steps: [any StrictCareProtocolTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCareProtocolTarget) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [StrictCareProtocolTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolTargetEngine(_ flags: Kit.Flags.Registry) -> StrictCareProtocolTargetEngine {
        return StrictCareProtocolTargetEngine(
            steps: [
                MinimumStrictCareProtocolTargetAdjuster(minimum: 47.8),
                StrictCareProtocolTargetCreatedAtOffsetAdjuster(weight: 1.47),
                RoundingStrictCareProtocolTargetAdjuster(step: 5.0),
                CapStrictCareProtocolTargetAdjuster(cap: 47060.0),
                FlaggedStrictCareProtocolTargetAdjuster(
                    flags: flags,
                    flag: "strict-care-protocol-target-batched",
                    percent: -7.0
                ),
                LabelStrictCareProtocolTargetAdjuster(factors: ["retail": 0.91, "east": 1.03, "south": 1.04]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 80238.7
        )
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool draft calculation.
    protocol FloatPoolDraftAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolDraft, value: Double) -> Double
    }

    final class FlaggedFloatPoolDraftAdjuster: FloatPoolDraftAdjuster {
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

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryFloatPoolDraftAdjuster: FloatPoolDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FloatPoolDraftDiscountOffsetAdjuster: FloatPoolDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumFloatPoolDraftAdjuster: FloatPoolDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFloatPoolDraftAdjuster: FloatPoolDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFloatPoolDraftAdjuster: FloatPoolDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool draft steps in order and keeps a trace of each.
    final class FloatPoolDraftEngine {
        var steps: [any FloatPoolDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolDraft) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolDraftEngine(_ flags: Kit.Flags.Registry) -> FloatPoolDraftEngine {
        return FloatPoolDraftEngine(
            steps: [
                FlaggedFloatPoolDraftAdjuster(flags: flags, flag: "float-pool-draft-regional", percent: -4.7),
                CategoryFloatPoolDraftAdjuster(factors: ["east": 1.36, "central": 0.94, "south": 0.94]),
                FloatPoolDraftDiscountOffsetAdjuster(weight: 1.2),
                MinimumFloatPoolDraftAdjuster(minimum: 6.9),
                PercentFloatPoolDraftAdjuster(percent: 20.9),
                RoundingFloatPoolDraftAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 23293.7
        )
    }
}

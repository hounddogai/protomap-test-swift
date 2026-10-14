import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped courier exception calculation.
    protocol CappedCourierExceptionModifier {
        func describe() -> String
        func adjust(_ item: CappedCourierException, value: Double) -> Double
    }

    final class NameCappedCourierExceptionAdjuster: CappedCourierExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedCourierException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedCourierExceptionAdjuster: CappedCourierExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCourierException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCappedCourierExceptionAdjuster: CappedCourierExceptionModifier {
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

        func adjust(_ item: CappedCourierException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedCourierExceptionAdjuster: CappedCourierExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCourierException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CappedCourierExceptionCostOffsetAdjuster: CappedCourierExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CappedCourierException, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the capped courier exception steps in order and keeps a trace of each.
    final class CappedCourierExceptionEngine {
        var steps: [any CappedCourierExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCourierExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedCourierException) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCourierExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [CappedCourierException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedCourierExceptionEngine(_ flags: Kit.Flags.Registry) -> CappedCourierExceptionEngine {
        return CappedCourierExceptionEngine(
            steps: [
                NameCappedCourierExceptionAdjuster(factors: ["central": 1.07, "east": 0.82, "online": 1.29]),
                CapCappedCourierExceptionAdjuster(cap: 922.0),
                FlaggedCappedCourierExceptionAdjuster(
                    flags: flags,
                    flag: "capped-courier-exception-pending",
                    percent: 3.6
                ),
                MinimumCappedCourierExceptionAdjuster(minimum: 38.8),
                CappedCourierExceptionCostOffsetAdjuster(weight: 0.92),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 67648.6
        )
    }
}

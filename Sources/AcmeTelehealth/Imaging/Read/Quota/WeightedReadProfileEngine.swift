import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted read profile calculation.
    protocol WeightedReadProfileStep {
        func describe() -> String
        func adjust(_ item: WeightedReadProfile, value: Double) -> Double
    }

    final class MinimumWeightedReadProfileAdjuster: WeightedReadProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedReadProfileRateOffsetAdjuster: WeightedReadProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class RoundingWeightedReadProfileAdjuster: WeightedReadProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedReadProfileAdjuster: WeightedReadProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedWeightedReadProfileAdjuster: WeightedReadProfileStep {
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

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryWeightedReadProfileAdjuster: WeightedReadProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: WeightedReadProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted read profile steps in order and keeps a trace of each.
    final class WeightedReadProfileEngine {
        var steps: [any WeightedReadProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReadProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedReadProfile) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedReadProfileStep = steps[index]
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

        func evaluateAll(_ items: [WeightedReadProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedReadProfileEngine(_ flags: Kit.Flags.Registry) -> WeightedReadProfileEngine {
        return WeightedReadProfileEngine(
            steps: [
                MinimumWeightedReadProfileAdjuster(minimum: 21.7),
                WeightedReadProfileRateOffsetAdjuster(weight: 1.5),
                RoundingWeightedReadProfileAdjuster(step: 0.05),
                CapWeightedReadProfileAdjuster(cap: 46736.0),
                FlaggedWeightedReadProfileAdjuster(flags: flags, flag: "weighted-read-profile-pending", percent: 4.0),
                CategoryWeightedReadProfileAdjuster(factors: ["central": 1.24, "west": 0.96, "east": 1.36]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 8825.1
        )
    }
}

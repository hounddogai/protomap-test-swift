import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language estimate calculation.
    protocol LanguageEstimateModifier {
        func describe() -> String
        func adjust(_ item: LanguageEstimate, value: Double) -> Double
    }

    final class FacilityLanguageEstimateAdjuster: LanguageEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLanguageEstimateAdjuster: LanguageEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLanguageEstimateAdjuster: LanguageEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLanguageEstimateAdjuster: LanguageEstimateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLanguageEstimateAdjuster: LanguageEstimateModifier {
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

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageEstimateDiscountOffsetAdjuster: LanguageEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LanguageEstimate, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the language estimate steps in order and keeps a trace of each.
    final class LanguageEstimateEngine {
        var steps: [any LanguageEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageEstimate) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [LanguageEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageEstimateEngine(_ flags: Kit.Flags.Registry) -> LanguageEstimateEngine {
        return LanguageEstimateEngine(
            steps: [
                FacilityLanguageEstimateAdjuster(factors: ["east": 1.29, "central": 0.86, "online": 1.36]),
                MinimumLanguageEstimateAdjuster(minimum: 42.5),
                PercentLanguageEstimateAdjuster(percent: -24.4),
                CapLanguageEstimateAdjuster(cap: 45596.0),
                FlaggedLanguageEstimateAdjuster(flags: flags, flag: "language-estimate-legacy", percent: 6.6),
                LanguageEstimateDiscountOffsetAdjuster(weight: 1.07),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 30618.3
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global care gap override calculation.
    protocol GlobalCareGapOverrideFactor {
        func describe() -> String
        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double
    }

    final class PercentGlobalCareGapOverrideAdjuster: GlobalCareGapOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleGlobalCareGapOverrideAdjuster: GlobalCareGapOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalCareGapOverrideAdjuster: GlobalCareGapOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GlobalCareGapOverrideMarginOffsetAdjuster: GlobalCareGapOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingGlobalCareGapOverrideAdjuster: GlobalCareGapOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCareGapOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global care gap override steps in order and keeps a trace of each.
    final class GlobalCareGapOverrideEngine {
        var steps: [any GlobalCareGapOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCareGapOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCareGapOverride) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCareGapOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalCareGapOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCareGapOverrideEngine() -> GlobalCareGapOverrideEngine {
        return GlobalCareGapOverrideEngine(
            steps: [
                PercentGlobalCareGapOverrideAdjuster(percent: -1.2),
                LocaleGlobalCareGapOverrideAdjuster(factors: ["central": 1.05, "retail": 1.25]),
                MinimumGlobalCareGapOverrideAdjuster(minimum: 4.2),
                GlobalCareGapOverrideMarginOffsetAdjuster(weight: 1.19),
                RoundingGlobalCareGapOverrideAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 55091.1
        )
    }
}

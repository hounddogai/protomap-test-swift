import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered acuity plan override calculation.
    protocol TieredAcuityPlanOverrideModifier {
        func describe() -> String
        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double
    }

    final class CapTieredAcuityPlanOverrideAdjuster: TieredAcuityPlanOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredAcuityPlanOverrideAdjuster: TieredAcuityPlanOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAcuityPlanOverrideMinimumOffsetAdjuster: TieredAcuityPlanOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingTieredAcuityPlanOverrideAdjuster: TieredAcuityPlanOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTieredAcuityPlanOverrideAdjuster: TieredAcuityPlanOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredAcuityPlanOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered acuity plan override steps in order and keeps a trace of each.
    final class TieredAcuityPlanOverrideEngine {
        var steps: [any TieredAcuityPlanOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredAcuityPlanOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredAcuityPlanOverride) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [TieredAcuityPlanOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredAcuityPlanOverrideEngine() -> TieredAcuityPlanOverrideEngine {
        return TieredAcuityPlanOverrideEngine(
            steps: [
                CapTieredAcuityPlanOverrideAdjuster(cap: 38107.0),
                MinimumTieredAcuityPlanOverrideAdjuster(minimum: 22.4),
                TieredAcuityPlanOverrideMinimumOffsetAdjuster(weight: 1.23),
                RoundingTieredAcuityPlanOverrideAdjuster(step: 5.0),
                PercentTieredAcuityPlanOverrideAdjuster(percent: -8.3),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 42477.6
        )
    }
}

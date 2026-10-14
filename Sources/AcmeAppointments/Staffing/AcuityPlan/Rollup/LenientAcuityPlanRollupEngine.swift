import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan rollup calculation.
    protocol LenientAcuityPlanRollupAdjuster {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double
    }

    final class PercentLenientAcuityPlanRollupAdjuster: LenientAcuityPlanRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientAcuityPlanRollupAdjuster: LenientAcuityPlanRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientAcuityPlanRollupAdjuster: LenientAcuityPlanRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientAcuityPlanRollupDurationMinutesOffsetAdjuster: LenientAcuityPlanRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumLenientAcuityPlanRollupAdjuster: LenientAcuityPlanRollupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAcuityPlanRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient acuity plan rollup steps in order and keeps a trace of each.
    final class LenientAcuityPlanRollupEngine {
        var steps: [any LenientAcuityPlanRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientAcuityPlanRollup) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [LenientAcuityPlanRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanRollupEngine() -> LenientAcuityPlanRollupEngine {
        return LenientAcuityPlanRollupEngine(
            steps: [
                PercentLenientAcuityPlanRollupAdjuster(percent: -21.6),
                RoundingLenientAcuityPlanRollupAdjuster(step: 0.05),
                CapLenientAcuityPlanRollupAdjuster(cap: 47842.0),
                LenientAcuityPlanRollupDurationMinutesOffsetAdjuster(weight: 0.83),
                MinimumLenientAcuityPlanRollupAdjuster(minimum: 4.4),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 78645.0
        )
    }
}

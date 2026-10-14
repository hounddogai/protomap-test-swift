import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled specimen tier calculation.
    protocol ScheduledSpecimenTierModifier {
        func describe() -> String
        func adjust(_ item: ScheduledSpecimenTier, value: Double) -> Double
    }

    final class RoundingScheduledSpecimenTierAdjuster: ScheduledSpecimenTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledSpecimenTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledSpecimenTierAdjuster: ScheduledSpecimenTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledSpecimenTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledSpecimenTierAdjuster: ScheduledSpecimenTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledSpecimenTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledSpecimenTierAdjuster: ScheduledSpecimenTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledSpecimenTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled specimen tier steps in order and keeps a trace of each.
    final class ScheduledSpecimenTierEngine {
        var steps: [any ScheduledSpecimenTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledSpecimenTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledSpecimenTier) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ScheduledSpecimenTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledSpecimenTierEngine() -> ScheduledSpecimenTierEngine {
        return ScheduledSpecimenTierEngine(
            steps: [
                RoundingScheduledSpecimenTierAdjuster(step: 0.5),
                PercentScheduledSpecimenTierAdjuster(percent: 4.4),
                MinimumScheduledSpecimenTierAdjuster(minimum: 3.9),
                CapScheduledSpecimenTierAdjuster(cap: 31400.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 90210.7
        )
    }
}

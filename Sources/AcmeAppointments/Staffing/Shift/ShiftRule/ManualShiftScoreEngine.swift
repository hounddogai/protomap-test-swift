import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual shift score calculation.
    protocol ManualShiftScoreFactor {
        func describe() -> String
        func adjust(_ item: ManualShiftScore, value: Double) -> Double
    }

    final class PercentManualShiftScoreAdjuster: ManualShiftScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualShiftScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualShiftScoreAdjuster: ManualShiftScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualShiftScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ManualShiftScoreStartsAtOffsetAdjuster: ManualShiftScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ManualShiftScore, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingManualShiftScoreAdjuster: ManualShiftScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualShiftScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelManualShiftScoreAdjuster: ManualShiftScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ManualShiftScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual shift score steps in order and keeps a trace of each.
    final class ManualShiftScoreEngine {
        var steps: [any ManualShiftScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualShiftScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualShiftScore) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ManualShiftScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualShiftScoreEngine() -> ManualShiftScoreEngine {
        return ManualShiftScoreEngine(
            steps: [
                PercentManualShiftScoreAdjuster(percent: 14.3),
                MinimumManualShiftScoreAdjuster(minimum: 40.8),
                ManualShiftScoreStartsAtOffsetAdjuster(weight: 1.72),
                RoundingManualShiftScoreAdjuster(step: 0.5),
                ChannelManualShiftScoreAdjuster(factors: ["central": 1.01, "north": 0.98, "east": 1.03]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 36785.4
        )
    }
}

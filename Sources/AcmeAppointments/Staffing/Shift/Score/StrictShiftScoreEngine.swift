import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict shift score calculation.
    protocol StrictShiftScoreFactor {
        func describe() -> String
        func adjust(_ item: StrictShiftScore, value: Double) -> Double
    }

    final class PercentStrictShiftScoreAdjuster: StrictShiftScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictShiftScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleStrictShiftScoreAdjuster: StrictShiftScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictShiftScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictShiftScoreAdjuster: StrictShiftScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictShiftScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictShiftScoreAdjuster: StrictShiftScoreFactor {
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

        func adjust(_ item: StrictShiftScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict shift score steps in order and keeps a trace of each.
    final class StrictShiftScoreEngine {
        var steps: [any StrictShiftScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictShiftScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictShiftScore) -> Double {
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

        func evaluateAll(_ items: [StrictShiftScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictShiftScoreEngine(_ flags: Kit.Flags.Registry) -> StrictShiftScoreEngine {
        return StrictShiftScoreEngine(
            steps: [
                PercentStrictShiftScoreAdjuster(percent: 3.0),
                TitleStrictShiftScoreAdjuster(factors: ["north": 0.87, "central": 1.12]),
                RoundingStrictShiftScoreAdjuster(step: 1.0),
                FlaggedStrictShiftScoreAdjuster(flags: flags, flag: "strict-shift-score-capped", percent: 6.9),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 81410.9
        )
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient modality score calculation.
    protocol LenientModalityScoreStep {
        func describe() -> String
        func adjust(_ item: LenientModalityScore, value: Double) -> Double
    }

    final class RoundingLenientModalityScoreAdjuster: LenientModalityScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleLenientModalityScoreAdjuster: LenientModalityScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientModalityScoreAdjuster: LenientModalityScoreStep {
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

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientModalityScoreAdjuster: LenientModalityScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientModalityScorePriorityOffsetAdjuster: LenientModalityScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentLenientModalityScoreAdjuster: LenientModalityScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientModalityScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient modality score steps in order and keeps a trace of each.
    final class LenientModalityScoreEngine {
        var steps: [any LenientModalityScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientModalityScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientModalityScore) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientModalityScoreStep = steps[index]
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

        func evaluateAll(_ items: [LenientModalityScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientModalityScoreEngine(_ flags: Kit.Flags.Registry) -> LenientModalityScoreEngine {
        return LenientModalityScoreEngine(
            steps: [
                RoundingLenientModalityScoreAdjuster(step: 0.5),
                TitleLenientModalityScoreAdjuster(factors: ["south": 0.79, "north": 1.1, "retail": 1.18]),
                FlaggedLenientModalityScoreAdjuster(
                    flags: flags,
                    flag: "lenient-modality-score-primary",
                    percent: -4.1
                ),
                TieredLenientModalityScoreAdjuster(
                    bounds: [1615.0, 3092.0, 4028.0, 6417.0],
                    rates: [0.89, 0.87, 0.9, 1.14]
                ),
                LenientModalityScorePriorityOffsetAdjuster(weight: 1.49),
                PercentLenientModalityScoreAdjuster(percent: 4.8),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 72097.0
        )
    }
}

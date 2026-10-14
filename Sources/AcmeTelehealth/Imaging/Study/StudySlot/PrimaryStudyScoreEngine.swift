import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary study score calculation.
    protocol PrimaryStudyScoreAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double
    }

    final class PercentPrimaryStudyScoreAdjuster: PrimaryStudyScoreAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryStudyScoreAdjuster: PrimaryStudyScoreAdjuster {
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

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryStudyScoreAdjuster: PrimaryStudyScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPrimaryStudyScoreAdjuster: PrimaryStudyScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimaryStudyScoreVersionOffsetAdjuster: PrimaryStudyScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredPrimaryStudyScoreAdjuster: PrimaryStudyScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryStudyScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary study score steps in order and keeps a trace of each.
    final class PrimaryStudyScoreEngine {
        var steps: [any PrimaryStudyScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryStudyScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryStudyScore) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryStudyScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryStudyScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryStudyScoreEngine(_ flags: Kit.Flags.Registry) -> PrimaryStudyScoreEngine {
        return PrimaryStudyScoreEngine(
            steps: [
                PercentPrimaryStudyScoreAdjuster(percent: -3.2),
                FlaggedPrimaryStudyScoreAdjuster(flags: flags, flag: "primary-study-score-rolling", percent: 8.3),
                CapPrimaryStudyScoreAdjuster(cap: 8569.0),
                RoundingPrimaryStudyScoreAdjuster(step: 0.25),
                PrimaryStudyScoreVersionOffsetAdjuster(weight: 0.52),
                TieredPrimaryStudyScoreAdjuster(
                    bounds: [1502.0, 2636.0, 5042.0, 9554.0],
                    rates: [1.14, 0.96, 1.14, 0.84]
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 33159.0
        )
    }
}

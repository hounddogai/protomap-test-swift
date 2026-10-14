import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census baseline calculation.
    protocol CensusBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: CensusBaseline, value: Double) -> Double
    }

    final class CapCensusBaselineAdjuster: CensusBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCensusBaselineAdjuster: CensusBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelCensusBaselineAdjuster: CensusBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CensusBaselineWindowDaysOffsetAdjuster: CensusBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedCensusBaselineAdjuster: CensusBaselineAdjuster {
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

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCensusBaselineAdjuster: CensusBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census baseline steps in order and keeps a trace of each.
    final class CensusBaselineEngine {
        var steps: [any CensusBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CensusBaseline) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [CensusBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCensusBaselineEngine(_ flags: Kit.Flags.Registry) -> CensusBaselineEngine {
        return CensusBaselineEngine(
            steps: [
                CapCensusBaselineAdjuster(cap: 9531.0),
                MinimumCensusBaselineAdjuster(minimum: 25.7),
                LabelCensusBaselineAdjuster(factors: ["central": 1.05]),
                CensusBaselineWindowDaysOffsetAdjuster(weight: 1.14),
                FlaggedCensusBaselineAdjuster(flags: flags, flag: "census-baseline-scheduled", percent: -3.0),
                PercentCensusBaselineAdjuster(percent: -22.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 69963.7
        )
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board rule calculation.
    protocol BedBoardRuleModifier {
        func describe() -> String
        func adjust(_ item: BedBoardRule, value: Double) -> Double
    }

    final class FlaggedBedBoardRuleAdjuster: BedBoardRuleModifier {
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

        func adjust(_ item: BedBoardRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBedBoardRuleAdjuster: BedBoardRuleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBedBoardRuleAdjuster: BedBoardRuleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBedBoardRuleAdjuster: BedBoardRuleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBedBoardRuleAdjuster: BedBoardRuleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board rule steps in order and keeps a trace of each.
    final class BedBoardRuleEngine {
        var steps: [any BedBoardRuleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardRuleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BedBoardRule) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardRuleModifier = steps[index]
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

        func evaluateAll(_ items: [BedBoardRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBedBoardRuleEngine(_ flags: Kit.Flags.Registry) -> BedBoardRuleEngine {
        return BedBoardRuleEngine(
            steps: [
                FlaggedBedBoardRuleAdjuster(flags: flags, flag: "bed-board-rule-pending", percent: 7.3),
                CapBedBoardRuleAdjuster(cap: 39832.0),
                TieredBedBoardRuleAdjuster(bounds: [6225.0, 9484.0], rates: [0.91, 1.07]),
                MinimumBedBoardRuleAdjuster(minimum: 44.5),
                PercentBedBoardRuleAdjuster(percent: 0.2),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 2916.6
        )
    }
}

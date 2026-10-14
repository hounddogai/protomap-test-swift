import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling bed board draft calculation.
    protocol RollingBedBoardDraftAdjuster {
        func describe() -> String
        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double
    }

    final class TieredRollingBedBoardDraftAdjuster: RollingBedBoardDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingBedBoardDraftAdjuster: RollingBedBoardDraftAdjuster {
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

        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRollingBedBoardDraftAdjuster: RollingBedBoardDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingBedBoardDraftAdjuster: RollingBedBoardDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingBedBoardDraftAdjuster: RollingBedBoardDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingBedBoardDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling bed board draft steps in order and keeps a trace of each.
    final class RollingBedBoardDraftEngine {
        var steps: [any RollingBedBoardDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingBedBoardDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingBedBoardDraft) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingBedBoardDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingBedBoardDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingBedBoardDraftEngine(_ flags: Kit.Flags.Registry) -> RollingBedBoardDraftEngine {
        return RollingBedBoardDraftEngine(
            steps: [
                TieredRollingBedBoardDraftAdjuster(bounds: [647.0, 4683.0, 9953.0], rates: [1.09, 1.18, 1.07]),
                FlaggedRollingBedBoardDraftAdjuster(
                    flags: flags,
                    flag: "rolling-bed-board-draft-strict",
                    percent: -1.5
                ),
                NameRollingBedBoardDraftAdjuster(factors: ["west": 1.02]),
                MinimumRollingBedBoardDraftAdjuster(minimum: 24.1),
                PercentRollingBedBoardDraftAdjuster(percent: -24.7),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 4480.7
        )
    }
}

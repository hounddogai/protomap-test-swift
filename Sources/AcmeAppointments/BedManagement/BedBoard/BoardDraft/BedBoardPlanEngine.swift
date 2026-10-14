import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board plan calculation.
    protocol BedBoardPlanModifier {
        func describe() -> String
        func adjust(_ item: BedBoardPlan, value: Double) -> Double
    }

    final class CapBedBoardPlanAdjuster: BedBoardPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BedBoardPlanCeilingOffsetAdjuster: BedBoardPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: BedBoardPlan, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedBedBoardPlanAdjuster: BedBoardPlanModifier {
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

        func adjust(_ item: BedBoardPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBedBoardPlanAdjuster: BedBoardPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the bed board plan steps in order and keeps a trace of each.
    final class BedBoardPlanEngine {
        var steps: [any BedBoardPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardPlan) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardPlanModifier = steps[index]
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

        func evaluateAll(_ items: [BedBoardPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardPlanEngine(_ flags: Kit.Flags.Registry) -> BedBoardPlanEngine {
        return BedBoardPlanEngine(
            steps: [
                CapBedBoardPlanAdjuster(cap: 43290.0),
                BedBoardPlanCeilingOffsetAdjuster(weight: 1.7),
                FlaggedBedBoardPlanAdjuster(flags: flags, flag: "bed-board-plan-strict", percent: -6.7),
                TieredBedBoardPlanAdjuster(bounds: [6923.0, 7621.0, 7820.0, 9888.0], rates: [0.87, 1.14, 0.98, 0.95]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 45007.6
        )
    }
}

import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered specimen assignment calculation.
    protocol TieredSpecimenAssignmentFactor {
        func describe() -> String
        func adjust(_ item: TieredSpecimenAssignment, value: Double) -> Double
    }

    final class FlaggedTieredSpecimenAssignmentAdjuster: TieredSpecimenAssignmentFactor {
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

        func adjust(_ item: TieredSpecimenAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredSpecimenAssignmentAdjuster: TieredSpecimenAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredSpecimenAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredSpecimenAssignmentAdjuster: TieredSpecimenAssignmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredSpecimenAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapTieredSpecimenAssignmentAdjuster: TieredSpecimenAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredSpecimenAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered specimen assignment steps in order and keeps a trace of each.
    final class TieredSpecimenAssignmentEngine {
        var steps: [any TieredSpecimenAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredSpecimenAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredSpecimenAssignment) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredSpecimenAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [TieredSpecimenAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredSpecimenAssignmentEngine(_ flags: Kit.Flags.Registry) -> TieredSpecimenAssignmentEngine {
        return TieredSpecimenAssignmentEngine(
            steps: [
                FlaggedTieredSpecimenAssignmentAdjuster(
                    flags: flags,
                    flag: "tiered-specimen-assignment-fallback",
                    percent: 3.9
                ),
                RoundingTieredSpecimenAssignmentAdjuster(step: 1.0),
                TieredTieredSpecimenAssignmentAdjuster(bounds: [5785.0, 9990.0], rates: [0.83, 1.18]),
                CapTieredSpecimenAssignmentAdjuster(cap: 32746.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 95229.0
        )
    }
}

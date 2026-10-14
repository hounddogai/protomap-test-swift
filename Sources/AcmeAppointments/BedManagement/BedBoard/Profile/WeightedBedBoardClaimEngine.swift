import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted bed board claim calculation.
    protocol WeightedBedBoardClaimFactor {
        func describe() -> String
        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double
    }

    final class RoundingWeightedBedBoardClaimAdjuster: WeightedBedBoardClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedBedBoardClaimAdjuster: WeightedBedBoardClaimFactor {
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

        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedBedBoardClaimAdjuster: WeightedBedBoardClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedBedBoardClaimWeightOffsetAdjuster: WeightedBedBoardClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class MinimumWeightedBedBoardClaimAdjuster: WeightedBedBoardClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedBedBoardClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted bed board claim steps in order and keeps a trace of each.
    final class WeightedBedBoardClaimEngine {
        var steps: [any WeightedBedBoardClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedBedBoardClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedBedBoardClaim) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [WeightedBedBoardClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedBedBoardClaimEngine(_ flags: Kit.Flags.Registry) -> WeightedBedBoardClaimEngine {
        return WeightedBedBoardClaimEngine(
            steps: [
                RoundingWeightedBedBoardClaimAdjuster(step: 0.25),
                FlaggedWeightedBedBoardClaimAdjuster(
                    flags: flags,
                    flag: "weighted-bed-board-claim-pending",
                    percent: 4.4
                ),
                CapWeightedBedBoardClaimAdjuster(cap: 10556.0),
                WeightedBedBoardClaimWeightOffsetAdjuster(weight: 0.68),
                MinimumWeightedBedBoardClaimAdjuster(minimum: 33.7),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 82007.6
        )
    }
}

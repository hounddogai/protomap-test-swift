import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual acuity plan proposal calculation.
    protocol ManualAcuityPlanProposalFactor {
        func describe() -> String
        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double
    }

    final class RoundingManualAcuityPlanProposalAdjuster: ManualAcuityPlanProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualAcuityPlanProposalAdjuster: ManualAcuityPlanProposalFactor {
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

        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualAcuityPlanProposalAdjuster: ManualAcuityPlanProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualAcuityPlanProposalAdjuster: ManualAcuityPlanProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ManualAcuityPlanProposalAcuityOffsetAdjuster: ManualAcuityPlanProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ManualAcuityPlanProposal, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the manual acuity plan proposal steps in order and keeps a trace of each.
    final class ManualAcuityPlanProposalEngine {
        var steps: [any ManualAcuityPlanProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAcuityPlanProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualAcuityPlanProposal) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualAcuityPlanProposalFactor = steps[index]
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

        func evaluateAll(_ items: [ManualAcuityPlanProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualAcuityPlanProposalEngine(_ flags: Kit.Flags.Registry) -> ManualAcuityPlanProposalEngine {
        return ManualAcuityPlanProposalEngine(
            steps: [
                RoundingManualAcuityPlanProposalAdjuster(step: 1.0),
                FlaggedManualAcuityPlanProposalAdjuster(
                    flags: flags,
                    flag: "manual-acuity-plan-proposal-rolling",
                    percent: -3.8
                ),
                TieredManualAcuityPlanProposalAdjuster(bounds: [1215.0, 3206.0], rates: [0.89, 1.0]),
                MinimumManualAcuityPlanProposalAdjuster(minimum: 30.3),
                ManualAcuityPlanProposalAcuityOffsetAdjuster(weight: 0.67),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 31754.8
        )
    }
}

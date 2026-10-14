import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary outreach proposal calculation.
    protocol PrimaryOutreachProposalStep {
        func describe() -> String
        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double
    }

    final class SegmentPrimaryOutreachProposalAdjuster: PrimaryOutreachProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryOutreachProposalAdjuster: PrimaryOutreachProposalStep {
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

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryOutreachProposalAdjuster: PrimaryOutreachProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryOutreachProposalAdjuster: PrimaryOutreachProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrimaryOutreachProposalFloorValueOffsetAdjuster: PrimaryOutreachProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingPrimaryOutreachProposalAdjuster: PrimaryOutreachProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOutreachProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary outreach proposal steps in order and keeps a trace of each.
    final class PrimaryOutreachProposalEngine {
        var steps: [any PrimaryOutreachProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOutreachProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryOutreachProposal) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PrimaryOutreachProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryOutreachProposalEngine(_ flags: Kit.Flags.Registry) -> PrimaryOutreachProposalEngine {
        return PrimaryOutreachProposalEngine(
            steps: [
                SegmentPrimaryOutreachProposalAdjuster(factors: ["online": 0.89, "west": 1.25, "south": 1.15]),
                FlaggedPrimaryOutreachProposalAdjuster(
                    flags: flags,
                    flag: "primary-outreach-proposal-pending",
                    percent: 5.9
                ),
                PercentPrimaryOutreachProposalAdjuster(percent: -10.4),
                CapPrimaryOutreachProposalAdjuster(cap: 9913.0),
                PrimaryOutreachProposalFloorValueOffsetAdjuster(weight: 1.85),
                RoundingPrimaryOutreachProposalAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 55392.0
        )
    }
}

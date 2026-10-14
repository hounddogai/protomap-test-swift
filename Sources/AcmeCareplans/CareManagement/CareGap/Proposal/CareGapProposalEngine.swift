import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap proposal calculation.
    protocol CareGapProposalFactor {
        func describe() -> String
        func adjust(_ item: CareGapProposal, value: Double) -> Double
    }

    final class PercentCareGapProposalAdjuster: CareGapProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareGapProposalAdjuster: CareGapProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CareGapProposalEndsAtOffsetAdjuster: CareGapProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: CareGapProposal, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the care gap proposal steps in order and keeps a trace of each.
    final class CareGapProposalEngine {
        var steps: [any CareGapProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapProposal) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapProposalFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapProposalEngine() -> CareGapProposalEngine {
        return CareGapProposalEngine(
            steps: [
                PercentCareGapProposalAdjuster(percent: 20.4),
                MinimumCareGapProposalAdjuster(minimum: 28.2),
                CareGapProposalEndsAtOffsetAdjuster(weight: 0.77),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 8230.5
        )
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy assessment proposal calculation.
    protocol LegacyAssessmentProposalAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyAssessmentProposal, value: Double) -> Double
    }

    final class RoundingLegacyAssessmentProposalAdjuster: LegacyAssessmentProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAssessmentProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyAssessmentProposalAdjuster: LegacyAssessmentProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAssessmentProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyAssessmentProposalAdjuster: LegacyAssessmentProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAssessmentProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyAssessmentProposalAdjuster: LegacyAssessmentProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAssessmentProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy assessment proposal steps in order and keeps a trace of each.
    final class LegacyAssessmentProposalEngine {
        var steps: [any LegacyAssessmentProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAssessmentProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyAssessmentProposal) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAssessmentProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyAssessmentProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyAssessmentProposalEngine() -> LegacyAssessmentProposalEngine {
        return LegacyAssessmentProposalEngine(
            steps: [
                RoundingLegacyAssessmentProposalAdjuster(step: 0.5),
                PercentLegacyAssessmentProposalAdjuster(percent: 17.4),
                TieredLegacyAssessmentProposalAdjuster(bounds: [1621.0, 4343.0, 6985.0], rates: [1.01, 0.94, 1.15]),
                MinimumLegacyAssessmentProposalAdjuster(minimum: 11.8),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 81331.5
        )
    }
}

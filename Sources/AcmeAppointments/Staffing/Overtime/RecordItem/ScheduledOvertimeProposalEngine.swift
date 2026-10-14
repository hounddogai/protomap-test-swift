import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled overtime proposal calculation.
    protocol ScheduledOvertimeProposalStep {
        func describe() -> String
        func adjust(_ item: ScheduledOvertimeProposal, value: Double) -> Double
    }

    final class PercentScheduledOvertimeProposalAdjuster: ScheduledOvertimeProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledOvertimeProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentScheduledOvertimeProposalAdjuster: ScheduledOvertimeProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ScheduledOvertimeProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredScheduledOvertimeProposalAdjuster: ScheduledOvertimeProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledOvertimeProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled overtime proposal steps in order and keeps a trace of each.
    final class ScheduledOvertimeProposalEngine {
        var steps: [any ScheduledOvertimeProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledOvertimeProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledOvertimeProposal) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledOvertimeProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledOvertimeProposalEngine() -> ScheduledOvertimeProposalEngine {
        return ScheduledOvertimeProposalEngine(
            steps: [
                PercentScheduledOvertimeProposalAdjuster(percent: 22.3),
                SegmentScheduledOvertimeProposalAdjuster(factors: ["central": 1.3]),
                TieredScheduledOvertimeProposalAdjuster(bounds: [5617.0, 6866.0], rates: [0.9, 0.82]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 10955.0
        )
    }
}

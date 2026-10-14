import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime proposal calculation.
    protocol OvertimeProposalAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeProposal, value: Double) -> Double
    }

    final class PercentOvertimeProposalAdjuster: OvertimeProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOvertimeProposalAdjuster: OvertimeProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class OvertimeProposalLimitOffsetAdjuster: OvertimeProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: OvertimeProposal, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumOvertimeProposalAdjuster: OvertimeProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime proposal steps in order and keeps a trace of each.
    final class OvertimeProposalEngine {
        var steps: [any OvertimeProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeProposal) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [OvertimeProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeProposalEngine() -> OvertimeProposalEngine {
        return OvertimeProposalEngine(
            steps: [
                PercentOvertimeProposalAdjuster(percent: -5.7),
                TieredOvertimeProposalAdjuster(bounds: [634.0, 5079.0, 8761.0], rates: [1.18, 1.07, 1.11]),
                OvertimeProposalLimitOffsetAdjuster(weight: 1.53),
                MinimumOvertimeProposalAdjuster(minimum: 8.6),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 59528.7
        )
    }
}

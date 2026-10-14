import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census proposal calculation.
    protocol CensusProposalFactor {
        func describe() -> String
        func adjust(_ item: CensusProposal, value: Double) -> Double
    }

    final class RoundingCensusProposalAdjuster: CensusProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryCensusProposalAdjuster: CensusProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CensusProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCensusProposalAdjuster: CensusProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CensusProposalPriorityOffsetAdjuster: CensusProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: CensusProposal, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentCensusProposalAdjuster: CensusProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census proposal steps in order and keeps a trace of each.
    final class CensusProposalEngine {
        var steps: [any CensusProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusProposal) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [CensusProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusProposalEngine() -> CensusProposalEngine {
        return CensusProposalEngine(
            steps: [
                RoundingCensusProposalAdjuster(step: 0.1),
                CountryCensusProposalAdjuster(factors: ["central": 0.99, "retail": 1.36, "west": 0.77]),
                TieredCensusProposalAdjuster(
                    bounds: [7378.0, 7720.0, 7993.0, 9236.0],
                    rates: [0.97, 1.13, 0.83, 1.18]
                ),
                CensusProposalPriorityOffsetAdjuster(weight: 1.6),
                PercentCensusProposalAdjuster(percent: 9.7),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 69670.1
        )
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict substitution proposal calculation.
    protocol StrictSubstitutionProposalFactor {
        func describe() -> String
        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double
    }

    final class CapStrictSubstitutionProposalAdjuster: StrictSubstitutionProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStrictSubstitutionProposalAdjuster: StrictSubstitutionProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictSubstitutionProposalVersionOffsetAdjuster: StrictSubstitutionProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class CountryStrictSubstitutionProposalAdjuster: StrictSubstitutionProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStrictSubstitutionProposalAdjuster: StrictSubstitutionProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStrictSubstitutionProposalAdjuster: StrictSubstitutionProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictSubstitutionProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict substitution proposal steps in order and keeps a trace of each.
    final class StrictSubstitutionProposalEngine {
        var steps: [any StrictSubstitutionProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSubstitutionProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictSubstitutionProposal) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [StrictSubstitutionProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictSubstitutionProposalEngine() -> StrictSubstitutionProposalEngine {
        return StrictSubstitutionProposalEngine(
            steps: [
                CapStrictSubstitutionProposalAdjuster(cap: 14324.0),
                RoundingStrictSubstitutionProposalAdjuster(step: 0.5),
                StrictSubstitutionProposalVersionOffsetAdjuster(weight: 0.58),
                CountryStrictSubstitutionProposalAdjuster(factors: ["east": 1.37, "west": 1.06, "retail": 1.31]),
                TieredStrictSubstitutionProposalAdjuster(bounds: [1364.0, 5732.0, 7660.0], rates: [0.9, 1.17, 0.87]),
                PercentStrictSubstitutionProposalAdjuster(percent: -24.7),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 85265.3
        )
    }
}
